import SwiftUI
import UIKit

enum RelativeFormatter {
    private static let f: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "ar")
        f.unitsStyle = .short
        return f
    }()
    static func string(from date: Date) -> String { f.localizedString(for: date, relativeTo: Date()) }
}

extension Int {
    var compact: String {
        switch self {
        case 1_000_000...: return String(format: "%.1fM", Double(self) / 1_000_000).replacingOccurrences(of: ".0", with: "")
        case 1_000...: return String(format: "%.1fK", Double(self) / 1_000).replacingOccurrences(of: ".0", with: "")
        default: return String(self)
        }
    }
}
