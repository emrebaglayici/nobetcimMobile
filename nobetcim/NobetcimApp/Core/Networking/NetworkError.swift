import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case missingAPIKey
    case invalidResponse
    case unauthorized
    case notFound
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
        case .notFound:
            "Bu bölgede nöbetçi eczane bulunamadı."
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
}
