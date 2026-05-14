import Foundation

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL = AppConfig.baseURL,
        apiKey: String = AppConfig.apiKey,
        session: URLSession = URLSession(configuration: .ephemeral)
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }

    func send<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        let request = try endpoint.makeRequest(baseURL: baseURL, apiKey: apiKey)

        do {
            return try await perform(request, as: type, allowsRetry: endpoint.method == .get)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type, allowsRetry: Bool) async throws -> T {
        do {
            return try await decode(request, as: type)
        } catch NetworkError.transport where allowsRetry {
            try await Task.sleep(for: .milliseconds(450))
            return try await decode(request, as: type)
        }
    }

    private func decode<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response): (Data, URLResponse)
        #if DEBUG
        print("NobetEcza request:", request.url?.absoluteString ?? "<missing url>")
        #endif
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            #if DEBUG
            print("NobetEcza response:", httpResponse.statusCode, request.url?.path ?? "")
            #endif
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                #if DEBUG
                print("Decoding error:", error)
                print(String(data: data, encoding: .utf8) ?? "<non-utf8 response>")
                #endif
                throw NetworkError.decoding
            }
        case 401, 403:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.server(httpResponse.statusCode)
        default:
            throw NetworkError.unknown
        }
    }
}
