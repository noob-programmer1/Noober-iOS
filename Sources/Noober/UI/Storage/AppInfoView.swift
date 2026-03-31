import SwiftUI
import MachO

struct AppInfoView: View {

    @State private var memoryUsed: String = "—"
    @State private var diskFree: String = "—"
    @State private var diskTotal: String = "—"
    @State private var copiedField: String?
    @State private var prefsExpanded = false
    @State private var soundEnabled: Bool = !NooberSound.isMuted

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    // MARK: - Static Info

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "—"
    }

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "—"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "Unknown"
            }
        }
        // On simulator, show the simulated device name instead of hardware ID
        if machine.hasPrefix("x86_64") || machine.hasPrefix("arm64") {
            return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? machine
        }
        return machine
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    private var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private var locale: String {
        Locale.current.identifier
    }

    private var timezone: String {
        TimeZone.current.identifier
    }

    private var totalMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                infoSection("App") {
                    infoRow("App Name", appName)
                    Divider()
                    infoRow("Bundle ID", bundleId)
                    Divider()
                    infoRow("Version", version)
                    Divider()
                    infoRow("Build", build)
                }

                infoSection("Device") {
                    infoRow("Model", deviceModel)
                    Divider()
                    infoRow("Name", deviceName)
                    Divider()
                    infoRow("OS", osVersion)
                    Divider()
                    infoRow("Locale", locale)
                    Divider()
                    infoRow("Timezone", timezone)
                }

                infoSection("Runtime") {
                    infoRow("App Memory", memoryUsed)
                    Divider()
                    infoRow("Total Memory", totalMemory)
                    Divider()
                    infoRow("Disk Free", diskFree)
                    Divider()
                    infoRow("Disk Total", diskTotal)
                }

                preferencesSection
            }
            .padding(16)
        }
        .onAppear { refreshDynamic() }
        .onReceive(timer) { _ in refreshDynamic() }
    }

    // MARK: - Preferences (collapsed by default)

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    prefsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: prefsExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("Preferences")
                        .font(.system(size: 12, weight: .bold))
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            if prefsExpanded {
                VStack(spacing: 0) {
                    HStack {
                        Text("Sound effects")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: $soundEnabled)
                            .labelsHidden()
                            .scaleEffect(0.8)
                            .onChange(of: soundEnabled) { newValue in
                                NooberSound.isMuted = !newValue
                            }
                    }
                    .padding(.vertical, 4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Section

    private func infoSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(NooberTheme.accent)
                .textCase(.uppercase)
                .padding(.bottom, 8)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
        }
    }

    // MARK: - Row

    private func infoRow(_ key: String, _ value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            NooberTheme.hapticSuccess()
            copiedField = key
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if copiedField == key { copiedField = nil }
            }
        } label: {
            HStack {
                Text(key)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(copiedField == key ? "Copied!" : value)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(copiedField == key ? NooberTheme.success : .primary)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dynamic Refresh

    private func refreshDynamic() {
        memoryUsed = Self.appMemoryUsage()
        let (free, total) = Self.diskSpace()
        diskFree = free
        diskTotal = total
    }

    private static func appMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
    }

    private static func diskSpace() -> (free: String, total: String) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeBytes = attrs[.systemFreeSize] as? Int64,
              let totalBytes = attrs[.systemSize] as? Int64
        else { return ("—", "—") }
        let fmt = ByteCountFormatter()
        fmt.countStyle = .file
        return (fmt.string(fromByteCount: freeBytes), fmt.string(fromByteCount: totalBytes))
    }
}
