import XCTest
@testable import Ashlarbed

private struct ProbeDTO: Decodable {
    var remainder: Double
}

private actor ScriptedCarrier: AshlarCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class SteepleClientTests: XCTestCase {
    private let url = URL(string: "https://ashlarbed-steeple.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"remainder\":1}".utf8), http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        _ = try await client.getJSON(ProbeDTO.self, from: url)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), SteepleClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(SteepleClient.userAgent, "Ashlarbed/1.0 (iOS; +https://ashlarbed-steeple.pro)")
        XCTAssertEqual(SteepleClient.contactURL.absoluteString, "https://ashlarbed-steeple.pro/contact-us")
        XCTAssertEqual(EpleyCite.marks.count, 2)
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"remainder\":4.5}".utf8), http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        let dto = try await client.getJSON(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.remainder, 4.5)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"remainder\":1}".utf8), http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? AshlarWireFault, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_secondTransientFailureIsTransport() async {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.cannotConnectToHost)),
            .failure(URLError(.timedOut)),
        ])
        let client = SteepleClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected transport")
        } catch {
            XCTAssertEqual(error as? AshlarWireFault, .transport)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_cancellationIsNotRetried() async {
        let carrier = ScriptedCarrier(results: [
            .failure(CancellationError()),
            .success((Data("{\"remainder\":1}".utf8), http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected cancelled")
        } catch {
            XCTAssertEqual(error as? AshlarWireFault, .cancelled)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        do {
            _ = try await client.getJSON(ProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? AshlarWireFault, .decoding)
        }
    }

    func test_citeDTOMapsToDomainMarks() async throws {
        let body = Data("{\"sources\":[{\"title\":\"Epley\",\"href\":\"https://en.wikipedia.org/wiki/One-repetition_maximum\"},{\"title\":\"\",\"href\":\"https://example.com\"}]}".utf8)
        let carrier = ScriptedCarrier(results: [
            .success((body, http(200))),
        ])
        let client = SteepleClient(carrier: carrier)
        let marks = try await client.citeMarks(from: url)
        XCTAssertEqual(marks.count, 1)
        XCTAssertEqual(marks.first?.title, "Epley")
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
