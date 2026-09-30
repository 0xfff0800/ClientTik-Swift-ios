import SwiftUI
import UIKit

enum SortOrder: String, CaseIterable, Identifiable {
    case original = "الافتراضي", newest = "الأحدث", oldest = "الأقدم", likes = "الأكثر إعجاباً"
    var id: String { rawValue }
}

@MainActor
final class FetchModel: ObservableObject {
    @Published var input = ""
    @Published var comments: [Comment] = []
    @Published var videoID: String?
    @Published var status = ""
    @Published var isError = false
    @Published var isLoading = false
    @Published var total = 0
    private var task: Task<Void, Never>?

    func start() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        task?.cancel()
        comments = []; videoID = nil; total = 0; isError = false
        isLoading = true
        status = "جاري تحديد الفيديو..."
        Haptics.tap()

        let raw = input
        task = Task { [weak self] in
            guard let self = self else { return }
            do {
                let id = try await TikTokService.resolveVideoID(from: raw)
                self.videoID = id
                self.status = "جاري جلب التعليقات..."
                try await TikTokService.fetchAllComments(videoID: id) { page, total in
                    self.comments.append(contentsOf: page)
                    self.total = max(self.total, total)
                    self.status = "تم جلب \(self.comments.count)" + (self.total > 0 ? " من \(self.total)" : "")
                }
                self.status = self.comments.isEmpty ? "لا توجد تعليقات على هذا الفيديو" : "اكتمل جلب \(self.comments.count) تعليق"
                Haptics.success()
            } catch is CancellationError {
                self.status = "تم الإيقاف - \(self.comments.count) تعليق"
            } catch {
                self.isError = true
                self.status = self.comments.isEmpty
                    ? error.localizedDescription
                    : "توقف الجلب (\(error.localizedDescription)) - تم حفظ \(self.comments.count) تعليق"
                Haptics.error()
            }
            self.isLoading = false
        }
    }

    func cancel() { task?.cancel() }

    func clear() {
        task?.cancel()
        comments = []; videoID = nil; status = ""; isError = false; total = 0; isLoading = false
    }
}
