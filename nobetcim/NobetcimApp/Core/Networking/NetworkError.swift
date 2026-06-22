import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case badRequest
    case notFound
    case rateLimited
    case notConfigured
    case server(Int)
    case decoding
    case transport(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "İstek adresi geçersiz."
        case .missingAPIKey:
            "API anahtarı yapılandırılmamış."
        case .invalidResponse:
            "Sunucudan geçerli yanıt alınamadı."
        case .unauthorized:
            "API yetkilendirmesi başarısız."
        case .badRequest:
            "Arama bilgileri geçersiz."
        case .notFound:
            "Bu bölgede sonuç bulunamadı."
        case .rateLimited:
            "Sunucu geçici olarak yoğun. Lütfen kısa süre sonra tekrar deneyin."
        case .notConfigured:
            "API şu anda yapılandırılmamış."
        case .server:
            "Eczane bilgileri alınamadı."
        case .decoding:
            "Eczane bilgileri okunamadı."
        case .transport:
            "İnternet bağlantınızı kontrol edin."
        case .unknown:
            "Beklenmeyen bir hata oluştu."
        }
    }

    var prefersStaleCache: Bool {
        switch self {
        case .rateLimited, .notConfigured, .server:
            true
        default:
            false
        }
    }
}
