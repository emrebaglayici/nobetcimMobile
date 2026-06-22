import SwiftUI

enum AppTheme {
    /// Site palette: https://nobetcim.info — pharmacy-red (#C41E3A)
    static let primary = Color(red: 196 / 255, green: 30 / 255, blue: 58 / 255)
    static let primarySoft = Color(red: 254 / 255, green: 226 / 255, blue: 226 / 255)
    static let notary = Color(red: 0 / 255, green: 166 / 255, blue: 166 / 255)
    static let notarySoft = Color(red: 224 / 255, green: 247 / 255, blue: 247 / 255)
    static let call = primary
    static let directions = primary
    static let warning = Color.orange
    static let cardCornerRadius: CGFloat = 16
    static let contentMaxWidth: CGFloat = 860
}
