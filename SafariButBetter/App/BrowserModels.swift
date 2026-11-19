import SwiftUI
import Foundation

enum SearchEngine: String, CaseIterable, Identifiable {
    case duckDuckGo
    case google
    case brave
    case bing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .duckDuckGo: return "DuckDuckGo"
        case .google: return "Google"
        case .brave: return "Brave Search"
        case .bing: return "Bing"
        }
    }

    func searchURL(for query: String) -> URL? {
        var components: URLComponents?
        switch self {
        case .duckDuckGo:
            components = URLComponents(string: "https://duckduckgo.com/")
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
        case .google:
            components = URLComponents(string: "https://www.google.com/search")
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
        case .brave:
            components = URLComponents(string: "https://search.brave.com/search")
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
        case .bing:
            components = URLComponents(string: "https://www.bing.com/search")
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
        }
        return components?.url
    }
}

enum BrowserAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct BrowserTab: Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: URL?
    var isPrivate: Bool
    var isLoading = false
    var progress = 0.0
    var canGoBack = false
    var canGoForward = false

    init(id: UUID = UUID(), title: String = "New Tab", url: URL? = nil, isPrivate: Bool = false) {
        self.id = id
        self.title = title
        self.url = url
        self.isPrivate = isPrivate
    }
}

struct BrowserBookmark: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var addedAt: Date = .now

    var destination: URL? { URL(string: url) }
}

struct BrowserHistoryItem: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var visitedAt: Date = .now

    var destination: URL? { URL(string: url) }
}
