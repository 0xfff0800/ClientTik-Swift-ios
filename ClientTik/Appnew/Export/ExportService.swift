import SwiftUI
import UIKit

enum ExportService {
    static func csvFile(for comments: [Comment], name: String) -> URL? {
        func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        var rows = ["username,nickname,comment,likes,replies,date,avatar,video_id"]
        let iso = ISO8601DateFormatter()
        for c in comments {
            rows.append([esc(c.username), esc(c.nickname), esc(c.text), String(c.likes), String(c.replies),
                         esc(c.date.map { iso.string(from: $0) } ?? ""), esc(c.avatar ?? ""), esc(c.videoID)].joined(separator: ","))
        }
        let csv = "\u{FEFF}" + rows.joined(separator: "\n")   // BOM ليفتح العربي بشكل صحيح في Excel
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).csv")
        do { try csv.write(to: url, atomically: true, encoding: .utf8); return url } catch { return nil }
    }
}
