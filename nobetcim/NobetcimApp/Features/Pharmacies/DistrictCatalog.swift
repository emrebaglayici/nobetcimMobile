import Foundation

/// API bazen aynı ilçeyi "Buca 1", "Buca 2" gibi bölgelere ayırır; kullanıcıya tek ilçe adı gösterilir.
enum DistrictCatalog {
    static func canonicalize(_ districts: [DistrictInfo]) -> (names: [String], slugs: [String: String]) {
        let grouped = Dictionary(grouping: districts.filter { !$0.name.isEmpty }) {
            $0.name.canonicalDistrictName
        }

        var names: [String] = []
        var slugs: [String: String] = [:]

        for canonical in Array(grouped.keys).sortedTurkish {
            guard let group = grouped[canonical], !canonical.isEmpty else { continue }
            names.append(canonical)
            slugs[canonical] = preferredSlug(for: canonical, in: group)
        }

        return (names, slugs)
    }

    private static func preferredSlug(for canonical: String, in group: [DistrictInfo]) -> String {
        let base = canonical.slugifiedTurkish
        if let exact = group.first(where: { $0.slug == base }) {
            return exact.slug
        }
        if let withoutSuffix = group.first(where: { !$0.slug.hasNumericDistrictSuffix }) {
            return withoutSuffix.slug
        }
        return group.first?.slug ?? base
    }
}

extension String {
    /// "Buca 1", "Bornova 2" → "Buca", "Bornova"
    var canonicalDistrictName: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: #" \d+$"#, options: .regularExpression) {
            return String(trimmed[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedTitleCasedTurkish
        }
        return trimmed.localizedTitleCasedTurkish
    }

    var hasNumericDistrictSuffix: Bool {
        range(of: #"-\d+$"#, options: .regularExpression) != nil
    }
}
