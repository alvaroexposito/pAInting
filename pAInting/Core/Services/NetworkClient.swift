import Foundation
import OSLog

enum NetworkError: LocalizedError {
    case invalidResponse
    case statusCode(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Respuesta no válida del servidor."
        case .statusCode(let code): "El servidor respondió con el código \(code)."
        case .decoding: "No se pudo interpretar la respuesta."
        }
    }
}

/// Cliente HTTP mínimo basado en `URLSession` y async/await.
struct NetworkClient {
    var session: URLSession = .shared
    var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func send<T: Decodable>(_ request: URLRequest, as type: T.Type = T.self) async throws -> T {
        Logger.network.debug("\(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.statusCode(http.statusCode) }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
