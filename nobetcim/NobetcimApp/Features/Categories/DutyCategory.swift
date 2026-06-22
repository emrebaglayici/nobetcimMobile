import Foundation

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
        case .pharmacy, .notary: true
        }
    }
}
