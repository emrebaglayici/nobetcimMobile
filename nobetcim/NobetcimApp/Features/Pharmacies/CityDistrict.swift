import Foundation

struct CityDistrict: Identifiable, Codable, Hashable {
    let city: String
    let citySlug: String
    let districts: [String]
    let districtSlugs: [String: String]

    var id: String { city }

    enum CodingKeys: String, CodingKey {
        case city
        case il
        case ad
        case name
        case slug
        case districts
        case districtSlugs
        case ilceler
        case children
    }

    init(city: String, citySlug: String? = nil, districts: [String], districtSlugs: [String: String] = [:]) {
        self.city = city
        self.citySlug = citySlug ?? city.slugifiedTurkish
        self.districts = districts
        self.districtSlugs = districtSlugs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        city = (try container.decodeFirstString(for: [.city, .il, .ad, .name]) ?? "").localizedTitleCasedTurkish
        citySlug = try container.decodeFirstString(for: [.slug]) ?? city.slugifiedTurkish
        districts = (try container.decodeFirstStringArray(for: [.districts, .ilceler, .children]) ?? [])
            .map { $0.localizedTitleCasedTurkish }
        districtSlugs = try container.decodeIfPresent([String: String].self, forKey: .districtSlugs) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(city, forKey: .city)
        try container.encode(citySlug, forKey: .slug)
        try container.encode(districts, forKey: .districts)
        try container.encode(districtSlugs, forKey: .districtSlugs)
    }

    func slug(forDistrict district: String?) -> String? {
        guard let district, !district.isEmpty else { return nil }
        let canonical = district.canonicalDistrictName
        if let slug = districtSlugs[canonical] { return slug }
        if let slug = districtSlugs[district] { return slug }
        if let match = districtSlugs.first(where: { $0.key.canonicalDistrictName.matchesTurkish(canonical) }) {
            return match.value
        }
        return canonical.slugifiedTurkish
    }
}

struct DistrictInfo: Identifiable, Codable, Hashable {
    let name: String
    let slug: String

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case name
        case ad
        case district
        case ilce
        case slug
    }

    init(name: String, slug: String? = nil) {
        self.name = name
        self.slug = slug ?? name.slugifiedTurkish
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawName = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .ad)
            ?? container.decodeIfPresent(String.self, forKey: .district)
            ?? container.decodeIfPresent(String.self, forKey: .ilce)
            ?? ""
        name = rawName.localizedTitleCasedTurkish
        slug = try container.decodeIfPresent(String.self, forKey: .slug) ?? name.slugifiedTurkish
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(slug, forKey: .slug)
    }
}

struct DistrictResponse: Decodable {
    let items: [DistrictInfo]

    enum CodingKeys: String, CodingKey {
        case data
        case districts
        case ilceler
        case results
        case items
    }

    init(from decoder: Decoder) throws {
        if let array = try? [DistrictInfo](from: decoder) {
            items = array.filter { !$0.name.isEmpty }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try (container.decodeIfPresent([DistrictInfo].self, forKey: .data)
            ?? container.decodeIfPresent([DistrictInfo].self, forKey: .districts)
            ?? container.decodeIfPresent([DistrictInfo].self, forKey: .ilceler)
            ?? container.decodeIfPresent([DistrictInfo].self, forKey: .results)
            ?? container.decodeIfPresent([DistrictInfo].self, forKey: .items)
            ?? []).filter { !$0.name.isEmpty }
    }
}

struct CityDistrictResponse: Decodable {
    let items: [CityDistrict]

    enum CodingKeys: String, CodingKey {
        case cities
        case data
        case results
        case items
    }

    init(from decoder: Decoder) throws {
        if let array = try? [CityDistrict](from: decoder) {
            items = array.cleaned
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try (container.decodeIfPresent([CityDistrict].self, forKey: .cities)
            ?? container.decodeIfPresent([CityDistrict].self, forKey: .data)
            ?? container.decodeIfPresent([CityDistrict].self, forKey: .results)
            ?? container.decodeIfPresent([CityDistrict].self, forKey: .items)
            ?? []).cleaned
    }
}

extension Array where Element == CityDistrict {
    var cleaned: [CityDistrict] {
        filter { !$0.city.isEmpty }
            .map { entry in
                let infos = entry.districts.map { DistrictInfo(name: $0, slug: entry.districtSlugs[$0]) }
                let catalog = DistrictCatalog.canonicalize(infos)
                return CityDistrict(
                    city: entry.city,
                    citySlug: entry.citySlug,
                    districts: catalog.names,
                    districtSlugs: catalog.slugs
                )
            }
            .sorted { $0.city.localizedStandardCompare($1.city) == .orderedAscending }
    }
}

extension Array where Element == String {
    var sortedTurkish: [String] {
        sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
}

private extension KeyedDecodingContainer where Key == CityDistrict.CodingKeys {
    func decodeFirstString(for keys: [Key]) throws -> String? {
        for key in keys {
            if let value = try? decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    func decodeFirstStringArray(for keys: [Key]) throws -> [String]? {
        for key in keys {
            if let values = try? decodeIfPresent([String].self, forKey: key) {
                return values
            }
            if let childObjects = try? decodeIfPresent([DistrictObject].self, forKey: key) {
                return childObjects.map(\.name)
            }
        }
        return nil
    }
}

private struct DistrictObject: Decodable {
    let name: String

    enum CodingKeys: String, CodingKey {
        case name
        case district
        case ilce
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .district)
            ?? container.decodeIfPresent(String.self, forKey: .ilce)
            ?? ""
    }
}

extension String {
    var slugifiedTurkish: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased()
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ç", with: "c")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
