import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var browser: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClearData = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Search engine", selection: $browser.searchEngine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.title).tag(engine)
                        }
                    }
                    Picker("Appearance", selection: $browser.appearance) {
                        ForEach(BrowserAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                } header: {
                    Text("PERSONALIZATION")
                } footer: {
                    Text("Choose the search provider used when you enter a search instead of a website address.")
                }

                Section {
                    Toggle("Block known trackers", isOn: $browser.blockTrackers)
                    Toggle("Prefer HTTPS", isOn: $browser.httpsOnly)
                } header: {
                    Text("PRIVACY & SECURITY")
                } footer: {
                    Text("Tracker blocking uses a built-in list of common analytics and advertising hosts. HTTPS preference upgrades typed HTTP addresses where possible; it cannot guarantee that every destination supports HTTPS.")
                }

                Section {
                    HStack {
                        Label("Open tabs", systemImage: "square.on.square")
                        Spacer()
                        Text("\(browser.tabs.count)").foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Saved bookmarks", systemImage: "bookmark")
                        Spacer()
                        Text("\(browser.bookmarks.count)").foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("History entries", systemImage: "clock")
                        Spacer()
                        Text("\(browser.history.count)").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("BROWSER")
                }

                Section {
                    Button(role: .destructive) { confirmClearData = true } label: {
                        Label("Clear History and Website Data", systemImage: "trash")
                    }
                } footer: {
                    Text("Bookmarks and browser preferences are kept. Private tabs do not add visits to history.")
                }

                Section {
                    HStack {
                        Text("Safari But Better")
                        Spacer()
                        Text("Version 1.0").foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/itzmnyzzzXD/safari-butbetter")!) {
                        Label("Source code on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                } header: {
                    Text("ABOUT")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Clear browsing data?", isPresented: $confirmClearData, titleVisibility: .visible) {
                Button("Clear History and Website Data", role: .destructive) { browser.clearBrowsingData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes saved history and website data for regular browsing sessions.")
            }
        }
    }
}
