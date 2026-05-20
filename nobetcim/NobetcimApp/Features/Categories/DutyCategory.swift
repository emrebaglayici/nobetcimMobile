import Foundation

/// Şu an yalnızca eczane modülü açıktır; diğer satırlar yakında bilgisidir.
enum DutyCategory: String, CaseIterable, Identifiable {
    case pharmacy
    case notary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pharmacy: "Nöbetçi eczaneler"
        case .notary: "Nöbetçi Noterler"
        }
    }

    var systemImage: String {
        switch self {
        case .pharmacy: "cross.case.fill"
        case .notary: "doc.text.fill"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .pharmacy: true
        case .notary: false
        }
    }
}
