import SwiftUI

@main
struct SafariButBetterApp: App {
    @StateObject private var browser = BrowserViewModel()

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environmentObject(browser)
                .preferredColorScheme(browser.appearance.colorScheme)
        }
    }
}
