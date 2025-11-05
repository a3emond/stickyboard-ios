import Foundation

@available(iOS 15.0, macOS 12.0, *)
public final class APIClient: @unchecked Sendable {
    private let config: APIConfig
    private let session: URLSession
    private let enc: JSONEncoder
    private let dec: JSONDecoder
    private let auth: AuthManager

    public init(config: APIConfig, auth: AuthManager, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.auth = auth

        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        enc = e

        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = iso.date(from: s) { return date }
            let legacy = DateFormatter()
            legacy.dateFormat = "yyyy-MM-dd HH:mm:ss"
            legacy.locale = Locale(identifier: "en_US_POSIX")
            legacy.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = legacy.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unrecognized date: \(s)")
        }
        dec = d

        Task { await auth.bind(client: self) }
    }

    // MARK: Public

    public func request<T: Decodable>(_ ep: Endpoint) async throws -> T {
        do {
            return try await internalRequest(ep, decode: T.self, allowRetry: true)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(underlying: error)
        }
    }

    internal func requestRaw<T: Decodable>(_ ep: Endpoint) async throws -> T {
        do {
            return try await internalRaw(ep, decode: T.self, allowRetry: true)
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.transport(underlying: error)
        }
    }

    // MARK: With envelope

    private func internalRequest<T: Decodable>(_ ep: Endpoint, decode: T.Type, allowRetry: Bool) async throws -> T {
        let req = try await buildRequest(ep)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(status: nil, body: nil)
        }

        // Detect if this call IS the refresh endpoint to avoid re-entrant refresh
        let isRefreshCall = pathsEqual(ep.path, config.refreshPath)

        switch http.statusCode {
        case 200...299:
            do {
                let wrapped = try dec.decode(ApiResponseDto<T>.self, from: data)
                if wrapped.success, let payload = wrapped.data { return payload }
                throw APIError.server(wrapped.message ?? "Unknown server error")
            } catch let decodeErr as DecodingError {
                throw APIError.decoding(String(describing: decodeErr))
            }

        case 401:
            if allowRetry && !isRefreshCall {
                try await auth.refreshIfPossible()
                return try await internalRequest(ep, decode: T.self, allowRetry: false)
            }
            if let ed = try? dec.decode(ErrorDto.self, from: data) {
                throw mapErrorDto(ed)
            }
            throw APIError.authInvalid("Unauthorized after retry")

        default:
            // Helpful debug output
            #if DEBUG
            if let body = String(data: data, encoding: .utf8) {
                print("API non-2xx (\(http.statusCode)) body:", body)
            }
            #endif
            if let ed = try? dec.decode(ErrorDto.self, from: data) {
                throw mapErrorDto(ed)
            }
            throw APIError.unknown(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    // MARK: Raw (no envelope)

    private func internalRaw<T: Decodable>(_ ep: Endpoint, decode: T.Type, allowRetry: Bool) async throws -> T {
        let req = try await buildRequest(ep)
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(status: nil, body: nil)
        }

        let isRefreshCall = pathsEqual(ep.path, config.refreshPath)

        switch http.statusCode {
        case 200...299:
            do { return try dec.decode(T.self, from: data) }
            catch let decodeErr as DecodingError { throw APIError.decoding(String(describing: decodeErr)) }

        case 401:
            if allowRetry && !isRefreshCall {
                try await auth.refreshIfPossible()
                return try await internalRaw(ep, decode: T.self, allowRetry: false)
            }
            if let ed = try? dec.decode(ErrorDto.self, from: data) {
                throw mapErrorDto(ed)
            }
            throw APIError.authInvalid("Unauthorized after retry")

        default:
            #if DEBUG
            if let body = String(data: data, encoding: .utf8) {
                print("API non-2xx (\(http.statusCode)) body:", body)
            }
            #endif
            if let ed = try? dec.decode(ErrorDto.self, from: data) {
                throw mapErrorDto(ed)
            }
            throw APIError.unknown(status: http.statusCode, body: String(data: data, encoding: .utf8))
        }
    }

    // MARK: Request builder

    private func buildRequest(_ ep: Endpoint) async throws -> URLRequest {
        let base = config.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = ep.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let fullURL = URL(string: base + "/" + path) else {
            throw APIError.unknown(status: nil, body: "Invalid URL")
        }

        var comps = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)!
        if !ep.query.isEmpty {
            comps.queryItems = ep.query.compactMap { k, v in v.map { URLQueryItem(name: k, value: $0) } }
        }
        guard let url = comps.url else {
            throw APIError.unknown(status: nil, body: "Invalid URL components")
        }

        var req = URLRequest(url: url)
        req.httpMethod = ep.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        ep.headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let b = ep.body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encodeBody(b)
        }

        if ep.requiresAuth, let token = await auth.currentAccessToken(), !token.isEmpty {
            req.setValue(config.accessHeaderPrefix + token, forHTTPHeaderField: config.accessHeaderName)
        }

        return req
    }

    private func encodeBody(_ body: Encodable) throws -> Data {
        struct AnyEnc: Encodable {
            let f: (Encoder) throws -> Void
            init(_ w: Encodable) { f = w.encode }
            func encode(to encoder: Encoder) throws { try f(encoder) }
        }
        return try enc.encode(AnyEnc(body))
    }

    // MARK: Helpers

    private func pathsEqual(_ a: String, _ b: String) -> Bool {
        func norm(_ s: String) -> String {
            s.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        }
        return norm(a) == norm(b)
    }
}
