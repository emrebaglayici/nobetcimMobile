import Foundation

extension String {
  /// Converts ALL CAPS / mixed API text to Turkish title case (each word capitalized).
  var localizedTitleCasedTurkish: String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    let locale = Locale(identifier: "tr_TR")
    return trimmed
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .map { word in
        word.lowercased(with: locale).capitalized(with: locale)
      }
      .joined(separator: " ")
  }

  func matchesTurkish(_ other: String) -> Bool {
    folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) ==
      other.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
  }
}
