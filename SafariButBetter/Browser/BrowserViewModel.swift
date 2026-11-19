import Foundation
import SwiftUI
import WebKit

@MainActor
final class BrowserViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var tabs: [BrowserTab] = [BrowserTab()]
    @Published var selectedTabID: UUID
    @Published var addressText = ""
    @Published var bookmarks: [BrowserBookmark] = [] {
        didSet { persist(bookmarks, key: Keys.bookmarks) }
    }
    @Published var history: [BrowserHistoryItem] = [] {
        didSet { persist(history, key: Keys.history) }
    }
    @Published var searchEngine: SearchEngine {
        didSet { UserDefaults.standard.set(searchEngine.rawValue, forKey: Keys.searchEngine) }
    }
    @Published var appearance: BrowserAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }
    @Published var blockTrackers: Bool {
        didSet {
            UserDefaults.standard.set(blockTrackers, forKey: Keys.blockTrackers)
            applyTrackerRulesToAllWebViews()
        }
    }
    @Published var httpsOnly: Bool {
        didSet { UserDefaults.standard.set(httpsOnly, forKey: Keys.httpsOnly) }
    }

    private enum Keys {
        static let bookmarks = "browser.bookmarks.v1"
        static let history = "browser.history.v1"
        static let searchEngine = "browser.searchEngine"
        static let appearance = "browser.appearance"
        static let blockTrackers = "browser.blockTrackers"
        static let httpsOnly = "browser.httpsOnly"
    }

    private var webViews: [UUID: WKWebView] = [:]
    private var observations: [UUID: [NSKeyValueObservation]] = [:]
    private var trackerRuleList: WKContentRuleList?
    private var installedRuleIDs: Set<UUID> = []

    private static let trackerRules = #"""
    [
      {"trigger":{"url-filter":".*","if-domain":["doubleclick.net","*.doubleclick.net"]},"action":{"type":"block"}},
      {"trigger":{"url-filter":".*","if-domain":["google-analytics.com","*.google-analytics.com"]},"action":{"type":"block"}},
      {"trigger":{"url-filter":".*","if-domain":["googletagmanager.com","*.googletagmanager.com"]},"action":{"type":"block"}},
      {"trigger":{"url-filter":".*","if-domain":["connect.facebook.net","*.connect.facebook.net"]},"action":{"type":"block"}},
      {"trigger":{"url-filter":".*","if-domain":["hotjar.com","*.hotjar.com"]},"action":{"type":"block"}},
      {"trigger":{"url-filter":".*","if-domain":["scorecardresearch.com","*.scorecardresearch.com"]},"action":{"type":"block"}}
    ]
    """#

    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == selectedTabID })
    }

    var activeWebView: WKWebView? {
        webViews[selectedTabID]
    }

    var currentURL: URL? {
        activeWebView?.url ?? activeTab?.url
    }

    var isCurrentPageBookmarked: Bool {
        guard let url = currentURL?.absoluteString else { return false }
        return bookmarks.contains(where: { $0.url == url })
    }

    override init() {
        let defaults = UserDefaults.standard
        let savedSearch = defaults.string(forKey: Keys.searchEngine).flatMap(SearchEngine.init(rawValue:)) ?? .duckDuckGo
        let savedAppearance = defaults.string(forKey: Keys.appearance).flatMap(BrowserAppearance.init(rawValue:)) ?? .system
        let savedBookmarks = Self.decode([BrowserBookmark].self, key: Keys.bookmarks)
        let savedHistory = Self.decode([BrowserHistoryItem].self, key: Keys.history)

        self.searchEngine = savedSearch
        self.appearance = savedAppearance
        self.blockTrackers = defaults.object(forKey: Keys.blockTrackers) as? Bool ?? true
        self.httpsOnly = defaults.object(forKey: Keys.httpsOnly) as? Bool ?? true
        self.bookmarks = savedBookmarks
        self.history = savedHistory
        let firstTab = BrowserTab()
        self.tabs = [firstTab]
        self.selectedTabID = firstTab.id
        super.init()

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "SafariButBetter.TrackerRules.v1",
            encodedContentRuleList: Self.trackerRules
        ) { [weak self] rules, _ in
            guard let rules else { return }
            Task { @MainActor [weak self] in
                self?.trackerRuleList = rules
                self?.applyTrackerRulesToAllWebViews()
            }
        }
    }

    // MARK: Navigation

    func loadAddress(_ input: String? = nil) {
        let raw = (input ?? addressText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        let destination: URL?
        if raw.contains(" ") || (!raw.contains(".") && !raw.contains("://")) {
            destination = searchEngine.searchURL(for: raw)
        } else {
            let candidate = raw.contains("://") ? raw : "https://\(raw)"
            destination = URL(string: candidate)
        }

        guard var url = destination else { return }
        if httpsOnly, url.scheme?.lowercased() == "http", var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.scheme = "https"
            url = components.url ?? url
        }

        let view = ensureWebView(for: selectedTabID)
        addressText = url.host ?? url.absoluteString
        view.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    func goBack() { activeWebView?.goBack() }
    func goForward() { activeWebView?.goForward() }
    func reload() { activeWebView?.reload() }
    func stopLoading() { activeWebView?.stopLoading() }

    // MARK: Tabs

    func createTab(isPrivate: Bool = false) {
        let tab = BrowserTab(isPrivate: isPrivate)
        tabs.append(tab)
        selectedTabID = tab.id
        addressText = ""
    }

    func selectTab(_ tab: BrowserTab) {
        selectedTabID = tab.id
        addressText = webViews[tab.id]?.url?.host ?? tab.url?.host ?? ""
    }

    func closeTab(_ tab: BrowserTab) {
        if let view = webViews.removeValue(forKey: tab.id) {
            view.stopLoading()
            view.navigationDelegate = nil
            view.uiDelegate = nil
        }
        observations[tab.id] = nil
        installedRuleIDs.remove(tab.id)
        tabs.removeAll { $0.id == tab.id }

        if tabs.isEmpty {
            let replacement = BrowserTab()
            tabs = [replacement]
            selectedTabID = replacement.id
            addressText = ""
        } else if selectedTabID == tab.id, let replacement = tabs.last {
            selectTab(replacement)
        }
    }

    // MARK: Bookmarks and history

    func toggleBookmarkForCurrentPage() {
        guard let url = currentURL else { return }
        let absolute = url.absoluteString
        if let existing = bookmarks.first(where: { $0.url == absolute }) {
            bookmarks.removeAll { $0.id == existing.id }
        } else {
            let title = activeTab?.title ?? url.host ?? absolute
            bookmarks.insert(BrowserBookmark(title: title, url: absolute), at: 0)
        }
    }

    func removeBookmark(_ bookmark: BrowserBookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
    }

    func removeHistoryItem(_ item: BrowserHistoryItem) {
        history.removeAll { $0.id == item.id }
    }

    func clearBrowsingData() {
        history.removeAll()
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { }
    }

    func open(_ url: URL) {
        addressText = url.host ?? url.absoluteString
        let view = ensureWebView(for: selectedTabID)
        view.load(URLRequest(url: url))
    }

    // MARK: Web view lifecycle

    private func ensureWebView(for tabID: UUID) -> WKWebView {
        if let existing = webViews[tabID] { return existing }
        let tab = tabs.first(where: { $0.id == tabID })
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = (tab?.isPrivate == true) ? .nonPersistent() : .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.isOpaque = false
        webViews[tabID] = view
        observe(view, for: tabID)
        applyTrackerRules(to: view, tabID: tabID)
        return view
    }

    private func observe(_ view: WKWebView, for tabID: UUID) {
        observations[tabID] = [
            view.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    self?.updateTab(tabID) {
                        $0.progress = webView.estimatedProgress
                        $0.isLoading = webView.isLoading
                    }
                }
            },
            view.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor [weak self] in self?.updateTab(tabID) { $0.canGoBack = webView.canGoBack } }
            },
            view.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor [weak self] in self?.updateTab(tabID) { $0.canGoForward = webView.canGoForward } }
            },
            view.observe(\.title, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    self?.updateTab(tabID) { $0.title = webView.title ?? webView.url?.host ?? "Untitled Page" }
                }
            },
            view.observe(\.url, options: [.new]) { [weak self] webView, _ in
                Task { @MainActor [weak self] in
                    self?.updateTab(tabID) { $0.url = webView.url }
                    if self?.selectedTabID == tabID { self?.addressText = webView.url?.host ?? "" }
                }
            }
        ]
    }

    private func applyTrackerRulesToAllWebViews() {
        for (id, view) in webViews { applyTrackerRules(to: view, tabID: id) }
    }

    private func applyTrackerRules(to view: WKWebView, tabID: UUID) {
        guard let rules = trackerRuleList else { return }
        if blockTrackers {
            guard !installedRuleIDs.contains(tabID) else { return }
            view.configuration.userContentController.add(rules)
            installedRuleIDs.insert(tabID)
        } else if installedRuleIDs.contains(tabID) {
            view.configuration.userContentController.remove(rules)
            installedRuleIDs.remove(tabID)
        }
    }

    private func updateTab(_ id: UUID, _ change: (inout BrowserTab) -> Void) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        change(&tabs[index])
    }

    private func tabID(for view: WKWebView) -> UUID? {
        webViews.first(where: { $0.value === view })?.key
    }

    private func recordVisit(for view: WKWebView) {
        guard let id = tabID(for: view),
              let url = view.url,
              tabs.first(where: { $0.id == id })?.isPrivate != true,
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }

        let item = BrowserHistoryItem(title: view.title ?? url.host ?? url.absoluteString, url: url.absoluteString)
        history.removeAll { $0.url == item.url }
        history.insert(item, at: 0)
        if history.count > 300 { history = Array(history.prefix(300)) }
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func decode<T: Decodable>(_ type: T.Type, key: String) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(type, from: data) else {
            if T.self == [BrowserBookmark].self { return [] as! T }
            if T.self == [BrowserHistoryItem].self { return [] as! T }
            fatalError("Unsupported persisted type")
        }
        return value
    }

    // MARK: WKNavigationDelegate / WKUIDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let id = tabID(for: webView) else { return }
        updateTab(id) { $0.isLoading = true; $0.progress = 0.05 }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let id = tabID(for: webView) else { return }
        updateTab(id) {
            $0.isLoading = false
            $0.progress = 1
            $0.url = webView.url
            $0.title = webView.title ?? webView.url?.host ?? "Untitled Page"
            $0.canGoBack = webView.canGoBack
            $0.canGoForward = webView.canGoForward
        }
        if selectedTabID == id { addressText = webView.url?.host ?? "" }
        recordVisit(for: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishFailedNavigation(for: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishFailedNavigation(for: webView)
    }

    private func finishFailedNavigation(for view: WKWebView) {
        guard let id = tabID(for: view) else { return }
        updateTab(id) { $0.isLoading = false; $0.progress = 0 }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        createTab(isPrivate: activeTab?.isPrivate ?? false)
        let newView = ensureWebView(for: selectedTabID)
        newView.load(navigationAction.request)
        return newView
    }
}
