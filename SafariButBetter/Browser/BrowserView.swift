import SwiftUI

private enum BrowserSheet: String, Identifiable {
    case tabs
    case bookmarks
    case history
    case settings
    var id: String { rawValue }
}

struct BrowserView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var addressFocused: Bool
    @State private var activeSheet: BrowserSheet?

    private var foreground: Color { colorScheme == .dark ? .white : Color(red: 0.10, green: 0.13, blue: 0.19) }
    private var muted: Color { colorScheme == .dark ? .white.opacity(0.58) : Color.black.opacity(0.48) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.035, green: 0.045, blue: 0.075), Color(red: 0.055, green: 0.065, blue: 0.105), Color(red: 0.025, green: 0.03, blue: 0.05)]
                    : [Color(red: 0.93, green: 0.95, blue: 0.99), Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.91, green: 0.94, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header
                addressBar

                if let webView = browser.activeWebView {
                    BrowserWebView(webView: webView)
                        .id(browser.selectedTabID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(alignment: .top) {
                            if browser.activeTab?.isLoading == true, let progress = browser.activeTab?.progress {
                                GeometryReader { proxy in
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.9))
                                        .frame(width: proxy.size.width * progress, height: 2)
                                }
                                .frame(height: 2)
                            }
                        }
                } else {
                    StartPageView()
                        .environmentObject(browser)
                }

                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .foregroundStyle(foreground)
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .tabs: TabOverviewView()
                case .bookmarks: BookmarkListView()
                case .history: HistoryListView()
                case .settings: SettingsView()
                }
            }
            .environmentObject(browser)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.60, blue: 1), Color(red: 0.40, green: 0.36, blue: 0.95)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 39, height: 39)
                Image(systemName: "safari.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Safari, rethought")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .tracking(-0.3)
                Text(browser.activeTab?.isPrivate == true ? "PRIVATE SESSION" : "YOUR BROWSER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.35)
                    .foregroundStyle(muted)
            }

            Spacer()

            Button { activeSheet = .bookmarks } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Saved bookmarks")

            Button { activeSheet = .history } label: {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Browsing history")

            Button { activeSheet = .settings } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, 2)
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            Image(systemName: browser.currentURL == nil ? "magnifyingglass" : "lock.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(muted)

            TextField("Search or enter website", text: $browser.addressText)
                .font(.system(size: 15, weight: .medium))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.go)
                .focused($addressFocused)
                .onSubmit {
                    browser.loadAddress()
                    addressFocused = false
                }
                .accessibilityLabel("Website address or search")

            if !browser.addressText.isEmpty {
                Button {
                    browser.addressText = ""
                    addressFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(muted)
                }
                .accessibilityLabel("Clear address")
            }

            Button {
                if browser.activeTab?.isLoading == true { browser.stopLoading() }
                else if browser.activeWebView != nil { browser.reload() }
                else { addressFocused = true }
            } label: {
                Image(systemName: browser.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(browser.activeTab?.isLoading == true ? "Stop loading" : "Reload page")
        }
        .padding(.horizontal, 15)
        .frame(height: 50)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(foreground.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.05), radius: 16, y: 7)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            toolbarButton("chevron.left", label: "Back", enabled: browser.activeTab?.canGoBack == true) { browser.goBack() }
            toolbarButton("chevron.right", label: "Forward", enabled: browser.activeTab?.canGoForward == true) { browser.goForward() }

            Spacer(minLength: 4)

            Button { browser.toggleBookmarkForCurrentPage() } label: {
                Image(systemName: browser.isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(browser.isCurrentPageBookmarked ? Color.accentColor : foreground)
                    .frame(width: 44, height: 42)
            }
            .disabled(browser.currentURL == nil)
            .accessibilityLabel(browser.isCurrentPageBookmarked ? "Remove bookmark" : "Add bookmark")

            if let url = browser.currentURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(foreground)
                        .frame(width: 44, height: 42)
                }
                .accessibilityLabel("Share page")
            } else {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(muted.opacity(0.5))
                        .frame(width: 44, height: 42)
                }
                .disabled(true)
            }

            Spacer(minLength: 4)

            Button { activeSheet = .tabs } label: {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(foreground, lineWidth: 1.5)
                        .frame(width: 21, height: 21)
                    Text("\(browser.tabs.count)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .offset(x: 8, y: -7)
                }
                .frame(width: 44, height: 42)
            }
            .accessibilityLabel("Tabs, \(browser.tabs.count) open")

            Button { browser.createTab() } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(foreground)
                    .frame(width: 42, height: 42)
            }
            .accessibilityLabel("New tab")
        }
        .padding(.horizontal, 9)
        .frame(height: 52)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(foreground.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.15 : 0.06), radius: 16, y: 6)
    }

    private func toolbarButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(enabled ? foreground : muted.opacity(0.38))
                .frame(width: 42, height: 42)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
