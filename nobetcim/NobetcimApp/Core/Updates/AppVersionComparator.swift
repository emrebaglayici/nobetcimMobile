import Foundation

enum AppVersionComparator {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = components(from: lhs)
        let right = components(from: rhs)
        let count = max(left.count, right.count)

        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }

    static func isVersion(_ current: String, olderThan required: String) -> Bool {
        compare(current, required) == .orderedAscending
    }

    private static func components(from version: String) -> [Int] {
        version
            .split(separator: ".")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}
