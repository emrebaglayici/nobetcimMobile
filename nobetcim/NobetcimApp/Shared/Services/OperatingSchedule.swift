import Foundation

enum PlaceOperatingStatus: Equatable {
    case open(String)
    case duty(String)
    case closed(String)

    var title: String {
        switch self {
        case let .open(title), let .duty(title), let .closed(title):
            title
        }
    }

    var isClosed: Bool {
        if case .closed = self { return true }
        return false
    }
}

enum OperatingSchedule {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul") ?? .current
        return calendar
    }

    static func pharmacyUsesCatalog(now: Date = Date()) -> Bool {
        isWeekday(now) && isTime(now, fromHour: 9, toHour: 19)
    }

    static func notaryUsesCatalog(now: Date = Date()) -> Bool {
        isWeekday(now)
    }

    static func status(kind: MapPlaceKind, now: Date = Date()) -> PlaceOperatingStatus {
        switch kind {
        case .pharmacy:
            return pharmacyUsesCatalog(now: now) ? .open("Açık") : .duty("Nöbetçi")
        case .notary:
            if isWeekday(now) {
                return isTime(now, fromHour: 9, toHour: 17) ? .open("Açık") : .closed("Kapalı")
            }
            return isTime(now, fromHour: 10, toHour: 16) ? .duty("Nöbetçi") : .closed("Kapalı")
        }
    }

    private static func isWeekday(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date)
        return weekday != 1 && weekday != 7
    }

    private static func isTime(_ date: Date, fromHour: Int, toHour: Int) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return minutes >= fromHour * 60 && minutes < toHour * 60
    }
}
