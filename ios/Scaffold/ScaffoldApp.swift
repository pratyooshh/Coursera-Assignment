import SwiftUI

@main
struct ScaffoldApp: App {
    @StateObject private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
