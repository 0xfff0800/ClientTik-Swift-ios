import SwiftUI
import UIKit

enum TikTokError: LocalizedError {
    case invalidInput, videoIDNotFound, badResponse

    var errorDescription: String? {
        switch self {
        case .invalidInput: return "أدخل رابط تيك توك أو رقم فيديو صحيح"
        case .videoIDNotFound: return "تعذر استخراج رقم الفيديو من الرابط"
        case .badResponse: return "استجابة غير صالحة من تيك توك"
        }
    }
}

enum TikTokService {
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    // MARK: Video ID

    /// يقبل رقم الفيديو مباشرة، أو أي رابط (قصير vt/vm أو كامل) ويرجع رقم الفيديو.
    static func resolveVideoID(from raw: String) async throws -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TikTokError.invalidInput }

        if text.allSatisfy(\.isNumber), text.count >= 15 { return text }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let url = match.url else { throw TikTokError.invalidInput }

        if let id = videoID(in: url.absoluteString) { return id }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await load(request)

        if let final = response.url?.absoluteString, let id = videoID(in: final) { return id }
        if let html = String(data: data, encoding: .utf8), let id = videoID(in: html) { return id }
        throw TikTokError.videoIDNotFound
    }

    private static func videoID(in string: String) -> String? {
        for pattern in ["/video/(\\d{15,25})", "/photo/(\\d{15,25})", "[?&]share_item_id=(\\d{15,25})", "\"video\":\\{\"id\":\"(\\d{15,25})\""] {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let m = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
               let r = Range(m.range(at: 1), in: string) {
                return String(string[r])
            }
        }
        return nil
    }

    // MARK: Comments

    /// يجلب كل الصفحات تلقائياً حتى تنتهي التعليقات. `onPage` يُستدعى على الـ main actor.
    static func fetchAllComments(videoID: String,
                                 onPage: @MainActor ([Comment], Int) -> Void) async throws {
        var cursor = 0
        var seen = Set<String>()
        var emptyStreak = 0

        while true {
            try Task.checkCancellation()

            let page = try await fetchPage(videoID: videoID, cursor: cursor)
            let fresh = (page.comments ?? []).map { Comment(api: $0, videoID: videoID) }.filter { seen.insert($0.cid).inserted }

            if !fresh.isEmpty {
                emptyStreak = 0
                await onPage(fresh, page.total ?? 0)
            } else {
                emptyStreak += 1
            }

            let next = page.cursor ?? (cursor + (page.comments?.count ?? 0))
            guard page.has_more == 1, next > cursor, emptyStreak < 3 else { return }
            cursor = next

            try await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    private static func fetchPage(videoID: String, cursor: Int) async throws -> APICommentList {
        var components = URLComponents(string: "https://www.tiktok.com/api/comment/list/")!
        components.queryItems = [
            URLQueryItem(name: "aid", value: "1988"),
            URLQueryItem(name: "aweme_id", value: videoID),
            URLQueryItem(name: "count", value: "50"),
            URLQueryItem(name: "cursor", value: String(cursor))
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.tiktok.com/@x/video/\(videoID)", forHTTPHeaderField: "Referer")

        var lastError: Error = TikTokError.badResponse
        for attempt in 0..<3 {
            try Task.checkCancellation()
            do {
                let (data, _) = try await load(request)
                return try JSONDecoder().decode(APICommentList.self, from: data)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                try await Task.sleep(nanoseconds: UInt64(attempt + 1) * 700_000_000)
            }
        }
        throw lastError
    }

    private final class TaskBox { var task: URLSessionDataTask? }

    // مغلّف متوافق مع iOS 14 (بدون URLSession.data(for:))
    private static func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let box = TaskBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                let t = session.dataTask(with: request) { data, response, error in
                    if let error = error { cont.resume(throwing: error) }
                    else if let data = data, let response = response { cont.resume(returning: (data, response)) }
                    else { cont.resume(throwing: TikTokError.badResponse) }
                }
                box.task = t
                t.resume()
            }
        } onCancel: {
            box.task?.cancel()
        }
    }
}
