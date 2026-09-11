import Foundation

/// Role: Steeple. Typed transport failures. This product has no remote catalog; contact is a Settings link.
enum AshlarWireFault: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Steeple. One HTTP hop. Injected so tests never leave the process.
protocol AshlarCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Steeple. URLSession hop, 15 s timeout, app User-Agent on every request.
struct AshlarSessionCarrier: AshlarCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": SteepleClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Steeple. DTO that mirrors cite JSON exactly. Never decoded into CiteMark.
struct CiteListDTO: Decodable, Sendable {
    var sources: [CiteRowDTO]
}

/// Role: Steeple. One cite row as the wire sent it.
struct CiteRowDTO: Decodable, Sendable {
    var title: String
    var href: String
}

/// Role: Steeple. Owns the session. No required remote catalog — contact URL is a Settings link, not fetched here.
actor SteepleClient {
    static let userAgent = "Ashlarbed/1.0 (iOS; +https://ashlarbed-steeple.pro)"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://ashlarbed-steeple.pro/contact-us")!

    private let carrier: any AshlarCarrying

    init(carrier: any AshlarCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = AshlarSessionCarrier()
    }

    func getJSON<DTO: Decodable & Sendable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw AshlarWireFault.cancelled
        } catch {
            throw AshlarWireFault.decoding
        }
    }

    func citeMarks(from url: URL) async throws -> [CiteMark] {
        let payload = try await getJSON(CiteListDTO.self, from: url)
        return payload.sources.compactMap { row in
            let title = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty, let href = URL(string: row.href) else { return nil }
            return CiteMark(title: title, url: href)
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as AshlarWireFault {
            throw fault
        } catch is CancellationError {
            throw AshlarWireFault.cancelled
        } catch {
            if Self.cancelled(error) {
                throw AshlarWireFault.cancelled
            }
            guard Self.transient(error) else { throw AshlarWireFault.transport }
            do {
                return try await send(request)
            } catch let fault as AshlarWireFault {
                throw fault
            } catch is CancellationError {
                throw AshlarWireFault.cancelled
            } catch {
                if Self.cancelled(error) { throw AshlarWireFault.cancelled }
                throw AshlarWireFault.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AshlarWireFault.invalidResponse
        }
        if http.statusCode == 404 {
            throw AshlarWireFault.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw AshlarWireFault.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
