import SwiftUI

private struct BrowserShortcut: Identifiable {
    let title: String
    let subtitle: String
    let symbol: String
    let address: String
    var id: String { address }
}

struct StartPageView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.colorScheme) private var colorScheme

    private let shortcuts = [
        BrowserShortcut(title: "DuckDuckGo", subtitle: "Search privately", symbol: "magnifyingglass", address: "https://duckduckgo.com"),
        BrowserShortcut(title: "GitHub", subtitle: "Build something", symbol: "chevron.left.forwardslash.chevron.right", address: "https://github.com"),
        BrowserShortcut(title: "YouTube", subtitle: "Watch and learn", symbol: "play.rectangle", address: "https://youtube.com"),
        BrowserShortcut(title: "Wikipedia", subtitle: "Explore knowledge", symbol: "books.vertical", address: "https://wikipedia.org")
    ]

    private var secondary: Color { colorScheme == .dark ? .white.opacity(0.56) : .black.opacity(0.48) }
    private var cardFill: Color { colorScheme == .dark ? .white.opacity(0.055) : .white.opacity(0.72) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 27) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(secondary)
                    Text("A clearer way\nto browse.")
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .tracking(-1.6)
                        .lineSpacing(-1)
                    Text("Less noise. More control.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(secondary)
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text("QUICK ACCESS")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(secondary)
                        Spacer()
                        Text("4 SHORTCUTS")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(secondary.opacity(0.75))
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 11), GridItem(.flexible(), spacing: 11)], spacing: 11) {
                        ForEach(shortcuts) { shortcut in
                            Button { browser.loadAddress(shortcut.address) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: shortcut.symbol)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 37, height: 37)
                                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(shortcut.title)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text(shortcut.subtitle)
                                            .font(.system(size: 10))
                                            .foregroundStyle(secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                                .background(cardFill, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(.primary.opacity(0.055), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !browser.bookmarks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("BOOKMARKS", trailing: "\(browser.bookmarks.count) SAVED")
                        ForEach(browser.bookmarks.prefix(4)) { bookmark in
                            if let url = bookmark.destination {
                                Button { browser.open(url) } label: {
                                    HStack(spacing: 11) {
                                        Image(systemName: "bookmark.fill")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.accentColor)
                                            .frame(width: 32, height: 32)
                                            .background(Color.accentColor.opacity(0.11), in: Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(bookmark.title).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary).lineLimit(1)
                                            Text(url.host ?? bookmark.url).font(.system(size: 11)).foregroundStyle(secondary).lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold)).foregroundStyle(secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !browser.history.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("RECENTLY VISITED", trailing: "LAST SESSIONS")
                        ForEach(browser.history.prefix(4)) { item in
                            if let url = item.destination {
                                Button { browser.open(url) } label: {
                                    HStack(spacing: 11) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(secondary)
                                            .frame(width: 32, height: 32)
                                            .background(cardFill, in: Circle())
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title).font(.system(size: 13, weight: .medium)).foregroundStyle(.primary).lineLimit(1)
                                            Text(url.host ?? item.url).font(.system(size: 11)).foregroundStyle(secondary).lineLimit(1)
                                        }
                                        Spacer()
                                        Text(item.visitedAt, style: .relative)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                HStack(spacing: 7) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Private tabs keep their history out of this list.")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(secondary)
                .padding(.top, 2)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 5)
        }
    }

    private func sectionHeader(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.5).foregroundStyle(secondary)
            Spacer()
            Text(trailing).font(.system(size: 9, weight: .medium, design: .rounded)).tracking(0.9).foregroundStyle(secondary.opacity(0.75))
        }
    }
}
