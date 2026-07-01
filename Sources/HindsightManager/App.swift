import SwiftUI

@main
struct HindsightManagerApp: App {
    @StateObject private var state = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(minWidth: 500, idealWidth: 500, maxWidth: 600,
                       minHeight: 480, idealHeight: 520, maxHeight: 700)
        }
    }
}
