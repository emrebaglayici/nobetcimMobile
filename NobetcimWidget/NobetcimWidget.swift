import SwiftUI
import WidgetKit

private let appGroupID = "group.talhagergin.nobetcim"
private let nearestPharmaciesKey = "nobetcim.widget.nearestPharmacies"
private let legacyNearestPharmacyKey = "nobetcim.widget.nearestPharmacy"

struct NearestPharmacyEntry: TimelineEntry {
    let date: Date
    let pharmacies: [WidgetPharmacy]
}

struct WidgetPharmacy: Codable {
    let id: String
    let name: String
    let district: String
    let city: String
    let address: String
    let phone: String?
    let distanceKm: Double?
    let cachedAt: Date
}

struct NearestPharmacyProvider: TimelineProvider {
    func placeholder(in context: Context) -> NearestPharmacyEntry {
        NearestPharmacyEntry(date: Date(), pharmacies: WidgetPharmacy.previews)
    }

    func getSnapshot(in context: Context, completion: @escaping (NearestPharmacyEntry) -> Void) {
        completion(NearestPharmacyEntry(date: Date(), pharmacies: loadPharmacies().ifEmpty(WidgetPharmacy.previews)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NearestPharmacyEntry>) -> Void) {
        let entry = NearestPharmacyEntry(date: Date(), pharmacies: loadPharmacies())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadPharmacies() -> [WidgetPharmacy] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        let decoder = JSONDecoder()

        if let data = defaults.data(forKey: nearestPharmaciesKey),
           let pharmacies = try? decoder.decode([WidgetPharmacy].self, from: data) {
            return Array(pharmacies.prefix(2))
        }

        if let legacyData = defaults.data(forKey: legacyNearestPharmacyKey),
           let pharmacy = try? decoder.decode(WidgetPharmacy.self, from: legacyData) {
            return [pharmacy]
        }

        return []
    }
}

struct NearestPharmacyWidgetView: View {
    let entry: NearestPharmacyEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let pharmacy = entry.pharmacies.first {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(.white)
                        .font(.caption.weight(.bold))
                        .frame(width: 24, height: 24)
                        .background(Color(red: 0.0, green: 0.55, blue: 0.44), in: Circle())
                    Text("En Yakın Eczane")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }

                if family == .systemSmall {
                    pharmacySummary(pharmacy)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(entry.pharmacies.prefix(2).enumerated()), id: \.element.id) { index, pharmacy in
                            pharmacyRow(pharmacy, index: index + 1)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .containerBackground(.background, for: .widget)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.0, green: 0.55, blue: 0.44))
                Text("Yakındaki eczane")
                    .font(.headline)
                Text("Uygulamayı açıp konumuna göre arama yapınca burada gösterilecek.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .containerBackground(.background, for: .widget)
        }
    }

    private func pharmacySummary(_ pharmacy: WidgetPharmacy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pharmacy.name.localizedTitleCasedTurkish)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text("\(pharmacy.district) / \(pharmacy.city)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let distanceKm = pharmacy.distanceKm {
                Label(String(format: "%.1f km", distanceKm), systemImage: "location.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.0, green: 0.55, blue: 0.44))
            }
        }
    }

    private func pharmacyRow(_ pharmacy: WidgetPharmacy, index: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color(red: 0.0, green: 0.55, blue: 0.44))
                .frame(width: 20, height: 20)
                .background(Color(red: 0.0, green: 0.55, blue: 0.44).opacity(0.12), in: Circle())

            pharmacySummary(pharmacy)
        }
    }
}

@main
struct NobetcimWidget: Widget {
    let kind = "NearestPharmacyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NearestPharmacyProvider()) { entry in
            NearestPharmacyWidgetView(entry: entry)
        }
        .configurationDisplayName("Yakındaki Eczane")
        .description("Konumuna göre bulunan en yakın nöbetçi eczaneyi gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension WidgetPharmacy {
    static let previews = [
        WidgetPharmacy(
            id: "preview-1",
            name: "Şifa Eczanesi",
            district: "Kadıköy",
            city: "İstanbul",
            address: "Moda Cad. No:24 Kadıköy/İstanbul",
            phone: "0216 000 00 01",
            distanceKm: 1.2,
            cachedAt: Date()
        ),
        WidgetPharmacy(
            id: "preview-2",
            name: "Hayat Eczanesi",
            district: "Üsküdar",
            city: "İstanbul",
            address: "Hakimiyet Cad. No:8 Üsküdar/İstanbul",
            phone: "0216 000 00 02",
            distanceKm: 1.8,
            cachedAt: Date()
        )
    ]
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}

private extension String {
    var localizedTitleCasedTurkish: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "tr_TR"))
            .capitalized(with: Locale(identifier: "tr_TR"))
    }
}

#Preview(as: .systemSmall) {
    NobetcimWidget()
} timeline: {
    NearestPharmacyEntry(date: Date(), pharmacies: WidgetPharmacy.previews)
}
