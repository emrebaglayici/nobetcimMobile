import Foundation

struct DailyCacheEnvelope<Value: Codable>: Codable {
    let dateKey: String
    let cachedAt: Date
    let value: Value
}

final class DailyCacheStore<Value: Codable> {
    private let userDefaults: UserDefaults
    private let key: String
    private let calendar: Calendar
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(key: String, userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.key = key
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    var todayKey: String {
        Self.dateKey(for: Date(), calendar: calendar)
    }

    func loadToday() -> Value? {
        guard
            let data = userDefaults.data(forKey: key),
            let envelope = try? decoder.decode(DailyCacheEnvelope<Value>.self, from: data),
            envelope.dateKey == todayKey
        else {
            return nil
        }
        return envelope.value
    }

    func hasTodayValue() -> Bool {
        guard
            let data = userDefaults.data(forKey: key),
            let envelope = try? decoder.decode(DailyCacheEnvelope<Value>.self, from: data)
        else {
            return false
        }
        return envelope.dateKey == todayKey
    }

    func loadAnyCachedValue() -> Value? {
        guard
            let data = userDefaults.data(forKey: key),
            let envelope = try? decoder.decode(DailyCacheEnvelope<Value>.self, from: data)
        else {
            return nil
        }
        return envelope.value
    }

    func saveToday(_ value: Value) {
        let envelope = DailyCacheEnvelope(dateKey: todayKey, cachedAt: Date(), value: value)
        guard let data = try? encoder.encode(envelope) else { return }
        userDefaults.set(data, forKey: key)
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}

final class PersistentCacheStore<Value: Codable> {
    private let userDefaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(key: String, userDefaults: UserDefaults = .standard) {
        self.key = key
        self.userDefaults = userDefaults
    }

    func load() -> Value? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(Value.self, from: data)
    }

    func save(_ value: Value) {
        guard let data = try? encoder.encode(value) else { return }
        userDefaults.set(data, forKey: key)
    }
}
