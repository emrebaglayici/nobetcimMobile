import Foundation

enum DutyCategory: String, CaseIterable, Identifiable {
    case pharmacy
    case towTruck
    case taxi
    case notary
    case veterinarian
    case emergency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pharmacy: "Nöbetçi Eczaneler"
        case .towTruck: "Açık Çekiciler"
        case .taxi: "Yakındaki Taksiler"
        case .notary: "Nöbetçi Noterler"
        case .veterinarian: "Açık Veterinerler"
        case .emergency: "Acil Yardım"
        }
    }

    var systemImage: String {
        switch self {
        case .pharmacy: "cross.case.fill"
        case .towTruck: "car.fill"
        case .taxi: "car.2.fill"
        case .notary: "doc.text.fill"
        case .veterinarian: "stethoscope"
        case .emergency: "sos.circle.fill"
        }
    }

    var isAvailable: Bool {
        self == .pharmacy
    }
}
