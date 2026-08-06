import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: DataStore
    @State private var selection: Tab = .today
    @State private var showingCapture = false

    enum Tab: Hashable {
        case today, focus, toolbox, learn, path
    }

    var body: some View {
        Group {
            if store.data.hasOnboarded {
                main
            } else {
                OnboardingView()
            }
        }
    }

    private var main: some View {
        TabView(selection: $selection) {
            TodayView(showingCapture: $showingCapture)
                .tabItem { Label("Today", systemImage: "sun.horizon") }
                .tag(Tab.today)

            FocusHomeView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(Tab.focus)

            ToolboxView()
                .tabItem { Label("Toolbox", systemImage: "cross.case") }
                .tag(Tab.toolbox)

            LibraryView()
                .tabItem { Label("Learn", systemImage: "books.vertical") }
                .tag(Tab.learn)

            PathView()
                .tabItem { Label("Path", systemImage: "signpost.right") }
                .tag(Tab.path)
        }
        .tint(Theme.violet)
        .sheet(isPresented: $showingCapture) {
            CaptureSheet()
        }
    }
}
