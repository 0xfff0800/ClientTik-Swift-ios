import SwiftUI
import UIKit

struct AboutMenuItems: View {
    @Binding var show: Bool
    var body: some View {
        Divider()
        Button { show = true } label: { Label("حول التطبيق والحقوق", systemImage: "info.circle") }
    }
}

struct AboutScreen: View {
    @EnvironmentObject var store: SavedStore
    @Environment(\.presentationMode) private var presentation
    @State private var cacheBytes = URLCache.shared.currentDiskUsage
    @State private var confirmClearSaved = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
    private var year: String { String(Calendar.current.component(.year, from: Date())) }
    private func size(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20).fill(Theme.gradient).frame(width: 72, height: 72)
                            Image(systemName: "text.bubble.fill").font(.system(size: 32)).foregroundColor(.white)
                        }
                        Text("تعليقات تيك توك").font(.title3.weight(.bold))
                        Text("الإصدار \(version)").font(.footnote).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Theme.card)
                    .cornerRadius(18)

                    section("الحقوق") {
                        row("person.fill", "المطوّر", "FaLaH")
                        Button {
                            if let url = URL(string: "https://twitter.com/0xFaLaH") { UIApplication.shared.open(url) }
                        } label: { row("at", "تويتر / X", "@0xFaLaH", chevron: true) }
                            .buttonStyle(PlainButtonStyle())
                        row("c.circle", "الحقوق", "© \(year) FaLaH")
                    }

                    section("البيانات والتخزين") {
                        row("bookmark.fill", "التعليقات المحفوظة", "\(store.items.count)")
                        row("internaldrive", "حجم المحفوظات", size(store.storageBytes))
                        row("photo", "ذاكرة الصور المؤقتة", size(cacheBytes))
                        Button {
                            URLCache.shared.removeAllCachedResponses()
                            cacheBytes = URLCache.shared.currentDiskUsage
                            Haptics.success()
                        } label: { action("trash", "مسح الذاكرة المؤقتة", color: .white).background(Theme.accent) }
                            .buttonStyle(PlainButtonStyle())
                        Button { confirmClearSaved = true } label: { action("bookmark.slash", "حذف كل المحفوظات", color: .red) }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(store.items.isEmpty)
                    }

                    section("ملاحظات") {
                        note("lock.fill", "الخصوصية", "كل المحفوظات تبقى على جهازك فقط ولا يتم إرسالها لأي جهة.")
                        note("link", "الروابط", "يقبل الرابط الكامل أو المختصر (vt / vm) أو رقم الفيديو مباشرة.")
                        note("hand.tap", "نصيحة", "اضغط مطولاً على أي تعليق لنسخه أو فتح حساب صاحبه أو حفظه.")
                        note("square.and.arrow.up", "التصدير", "يمكن تصدير التعليقات بصيغة CSV وفتحها في Excel أو Numbers.")
                        note("exclamationmark.triangle", "تنبيه", "التطبيق مستقل وغير تابع لتيك توك. قد يتوقف الجلب إذا غيّرت المنصة واجهتها أو حدّت الطلبات.")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationBarTitle("حول التطبيق", displayMode: .inline)
            .navigationBarItems(leading: Button("تم") { presentation.wrappedValue.dismiss() })
            .alert(isPresented: $confirmClearSaved) {
                Alert(title: Text("حذف كل المحفوظات؟"), message: Text("لا يمكن التراجع عن هذا الإجراء"),
                      primaryButton: .destructive(Text("حذف")) { store.removeAll() },
                      secondaryButton: .cancel(Text("إلغاء")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote).foregroundColor(.secondary).padding(.horizontal, 6)
            VStack(spacing: 0) { content() }
                .background(Theme.card)
                .cornerRadius(16)
        }
    }

    private func row(_ icon: String, _ title: String, _ value: String, chevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.accent).frame(width: 24)
            Text(title)
            Spacer()
            Text(verbatim: value).foregroundColor(.secondary).environment(\.layoutDirection, .leftToRight)
            if chevron { Image(systemName: "chevron.left").font(.caption).foregroundColor(.secondary) }
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private func action(_ icon: String, _ title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 24)
            Text(title)
            Spacer()
        }
        .foregroundColor(color)
        .padding(14)
        .contentShape(Rectangle())
    }

    private func note(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.accent).frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}
