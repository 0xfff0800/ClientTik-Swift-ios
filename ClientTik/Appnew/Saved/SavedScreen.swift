import SwiftUI
import UIKit

struct SavedScreen: View {
    @EnvironmentObject var store: SavedStore
    @State private var search = ""
    @State private var shareItems: [Any]?
    @State private var showAbout = false
    @State private var confirmClear = false

    private var visible: [Comment] {
        guard !search.isEmpty else { return store.items }
        return store.items.filter {
            $0.text.localizedCaseInsensitiveContains(search) ||
            $0.username.localizedCaseInsensitiveContains(search) ||
            $0.nickname.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if store.items.isEmpty {
                        EmptyState(icon: "bookmark", title: "لا توجد تعليقات محفوظة",
                                   message: "اضغط على علامة الحفظ في أي تعليق ليظهر هنا، وتبقى محفوظة حتى بعد إغلاق التطبيق")
                            .padding(.top, 80)
                    } else {
                        SearchField(text: $search, placeholder: "ابحث في المحفوظات")
                        if visible.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "لا نتائج", message: "جرّب كلمة بحث مختلفة").padding(.top, 30)
                        }
                        ForEach(visible) { c in
                            CommentCard(comment: c, videoID: c.videoID)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationBarTitle("المحفوظات", displayMode: .large)
            .navigationBarItems(trailing: Menu {
                Button { shareItems = [ExportService.csvFile(for: store.items, name: "saved-comments")].compactMap { $0 } } label: {
                    Label("تصدير CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(store.items.isEmpty)
                Button { confirmClear = true } label: {
                    Label("حذف الكل", systemImage: "trash")
                }
                .disabled(store.items.isEmpty)
                AboutMenuItems(show: $showAbout)
            } label: { Image(systemName: "ellipsis.circle").font(.title3) })
            .alert(isPresented: $confirmClear) {
                Alert(title: Text("حذف كل المحفوظات؟"), message: Text("لا يمكن التراجع عن هذا الإجراء"),
                      primaryButton: .destructive(Text("حذف")) { store.removeAll() },
                      secondaryButton: .cancel(Text("إلغاء")))
            }
            .sheet(isPresented: Binding(get: { shareItems != nil }, set: { if !$0 { shareItems = nil } })) {
                ShareSheet(items: shareItems ?? [])
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAbout) {
            AboutScreen().environmentObject(store).environment(\.layoutDirection, .rightToLeft)
        }
    }
}
