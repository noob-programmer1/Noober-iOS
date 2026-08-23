import SwiftUI
import Noober

@main
struct NooberSampleApp: App {

    init() {
        Noober.shared.registerEnvironments([
            .init(name: "Local", baseURL: "http://127.0.0.1:8765"),
            .init(name: "Staging", baseURL: "https://staging.example.com")
        ])

        Noober.shared.registerChecklist([
            .init("WebSocket frame detail", notes: "Full payload + copy", priority: .high),
            .init("Floating bubble calm mode", notes: "Idle dim, failure-only flash")
        ])

        Noober.shared.registerActions([
            .init("Log Something", icon: "text.alignleft") {
                Noober.shared.log("Hello from the sample app", level: .info, category: LogCategory("Sample"))
            }
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // `start()` needs a live UIWindowScene to attach the floating bubble to,
                // so it belongs here (or in `didFinishLaunching`) rather than in `App.init`.
                .onAppear { Noober.shared.start() }
        }
    }
}
