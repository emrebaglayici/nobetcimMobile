import Foundation

extension String {
    var localizedTitleCasedTurkish: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "tr_TR"))
            .capitalized(with: Locale(identifier: "tr_TR"))
    }
}
