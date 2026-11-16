import SwiftUI

// ألوان التطبيق في مكان واحد
enum Theme {
    static let orange     = Color(red: 1.00, green: 0.57, blue: 0.19)
    static let orangeDark = Color(red: 0.35, green: 0.19, blue: 0.08)
    static let cyan       = Color(red: 0.20, green: 0.80, blue: 1.00)
    static let cyanDark   = Color(red: 0.07, green: 0.25, blue: 0.32)
    static let card       = Color(white: 0.12)
    static let chip       = Color(white: 0.17)
    static let disabled   = Color(white: 0.14)
}

extension Calendar {
    // تقويم ميلادي دايمًا، حتى لو جهازك هجري
    static let app = Calendar(identifier: .gregorian)
}

extension Date {
    func asText(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .app
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
