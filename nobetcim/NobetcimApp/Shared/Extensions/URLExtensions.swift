import CoreLocation
import Foundation
import UIKit

enum AppActions {
    static func call(_ phone: String?) {
        guard let phone, !phone.isEmpty else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    static func openAppleMaps(for pharmacy: Pharmacy) {
        guard let coordinate = pharmacy.coordinate else { return }
        let query = pharmacy.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Eczane"
        let urlString = "http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)&q=\(query)"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    static func openGoogleMaps(for pharmacy: Pharmacy) {
        guard let coordinate = pharmacy.coordinate else { return }
        let appURL = URL(string: "comgooglemaps://?q=\(coordinate.latitude),\(coordinate.longitude)")!
        let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(coordinate.latitude),\(coordinate.longitude)")!
        UIApplication.shared.open(appURL) { didOpen in
            if !didOpen {
                UIApplication.shared.open(webURL)
            }
        }
    }
}
