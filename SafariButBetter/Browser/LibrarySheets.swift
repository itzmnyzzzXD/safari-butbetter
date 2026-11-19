import SwiftUI

struct TabOverviewView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(browser.tabs) { tab in
                        Button {
                            browser.selectTab(tab)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: tab.isPrivate ? "hand.raised.fill" : "globe")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(tab.isPrivate ? .purple : .accentColor)
                                    .frame(width: 38, height: 38)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tab.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary).lineLimit(1)
                                    Text(tab.url?.host ?? (tab.isPrivate ? "Private tab" : "New tab"))
                                        .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                if tab.id == browser.selectedTabID {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) { browser.closeTab(tab) } label: { Label("Close", systemImage: "xmark") }
                        }
                    }
                } header: {
                    Text("\(browser.tabs.count) OPEN \(browser.tabs.count == 1 ? "TAB" : "TABS")")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Private") {
                        browser.createTab(isPrivate: true)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        browser.createTab()
                        dismiss()
                    } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New tab")
                }
            }
        }
    }
}

struct BookmarkListView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if browser.bookmarks.isEmpty {
                    ContentUnavailableView("No bookmarks yet", systemImage: "bookmark", description: Text("Save a page with the bookmark button to find it here."))
                } else {
                    List {
                        ForEach(browser.bookmarks) { bookmark in
                            Button {
                                if let url = bookmark.destination { browser.open(url); dismiss() }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bookmark.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary)
                                    Text(bookmark.destination?.host ?? bookmark.url).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                            .swipeActions {
                                Button(role: .destructive) { browser.removeBookmark(bookmark) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct HistoryListView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            Group {
                if browser.history.isEmpty {
                    ContentUnavailableView("No browsing history", systemImage: "clock", description: Text("Pages you visit in regular tabs will appear here."))
                } else {
                    List {
                        ForEach(browser.history) { item in
                            Button {
                                if let url = item.destination { browser.open(url); dismiss() }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.primary).lineLimit(1)
                                    HStack {
                                        Text(item.destination?.host ?? item.url).lineLimit(1)
                                        Spacer()
                                        Text(item.visitedAt, style: .relative)
                                    }
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                            .swipeActions {
                                Button(role: .destructive) { browser.removeHistoryItem(item) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear") { confirmClear = true }
                        .disabled(browser.history.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Clear browsing data?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear History and Website Data", role: .destructive) { browser.clearBrowsingData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This clears saved browsing history and website data for regular browsing sessions.")
            }
        }
    }
}
