import SwiftUI
import Noober

struct ContentView: View {

    @StateObject private var client = DemoClient()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Status")) {
                    Text(client.status)
                        .font(.system(size: 13, design: .monospaced))
                    HStack {
                        Circle()
                            .fill(client.isConnected ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(client.isConnected ? "WebSocket connected" : "WebSocket disconnected")
                            .font(.system(size: 13))
                    }
                }

                Section(header: Text("WebSocket")) {
                    button("Connect", "bolt.horizontal.circle") { client.connect() }
                    button("Send small text", "text.bubble") { client.sendSmallText() }
                    button("Send big JSON", "doc.text.magnifyingglass") { client.sendBigJSON() }
                    button("Send binary frame", "cube") { client.sendBinary() }
                    button("Toggle auto chat (2s)", "repeat") { client.toggleAutoChat() }
                    button("Disconnect", "xmark.circle") { client.disconnect() }
                }

                Section(header: Text("HTTP")) {
                    button("GET 200", "arrow.down.circle") { client.sendHTTP(path: "/ok") }
                    button("POST JSON", "arrow.up.circle") {
                        client.sendHTTP(path: "/echo", method: "POST", body: ["hello": "world"])
                    }
                    button("GET 500 (failure flash)", "exclamationmark.triangle") { client.sendHTTP(path: "/boom") }
                    button("Burst of 6 requests", "square.stack.3d.up") { client.sendBurst() }
                }

                Section(header: Text("Debugger")) {
                    button("Open Noober", "ant.fill") { Noober.shared.showDebugger() }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle("Noober Sample")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func button(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .accessibility(identifier: title)
    }
}
