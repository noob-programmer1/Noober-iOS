import SwiftUI

struct QAChecklistListView: View {

    @ObservedObject var store: QAChecklistStore
    @State private var failingItem: QAChecklistResult?

    var body: some View {
        if store.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                headerBar
                Divider()
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.sortedResults) { result in
                            checklistCard(result)
                        }
                    }
                    .padding(16)
                }
                shareFullReportButton
            }
            .sheet(item: $failingItem) { item in
                QAFailReportSheet(item: item, store: store)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 8) {
            Text("Build \(store.buildNumber)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                statLabel(count: store.totalCount, label: "items", color: .primary)
                statLabel(count: store.passedCount, label: "passed", color: NooberTheme.success)
                statLabel(count: store.failedCount, label: "failed", color: NooberTheme.error)
                statLabel(count: store.pendingCount, label: "pending", color: .secondary)
            }

            GeometryReader { geo in
                let total = max(store.totalCount, 1)
                let passedWidth = geo.size.width * CGFloat(store.passedCount) / CGFloat(total)
                let failedWidth = geo.size.width * CGFloat(store.failedCount) / CGFloat(total)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(uiColor: .tertiarySystemFill))
                    HStack(spacing: 0) {
                        if passedWidth > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(NooberTheme.success)
                                .frame(width: passedWidth)
                        }
                        if failedWidth > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(NooberTheme.error)
                                .frame(width: failedWidth)
                        }
                    }
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func statLabel(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Card

    private func checklistCard(_ result: QAChecklistResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Priority badge + title + status icon
            HStack(spacing: 8) {
                if result.priority == .high {
                    priorityBadge("HIGH", color: NooberTheme.error)
                } else if result.priority == .low {
                    priorityBadge("LOW", color: .secondary)
                }

                Text(result.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Spacer()

                statusIcon(result.status)
            }

            // Dev notes
            if !result.notes.isEmpty {
                Text(result.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            // Endpoint tags
            if !result.endpoints.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(result.endpoints, id: \.self) { endpoint in
                            Text(endpoint)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(NooberTheme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(NooberTheme.accent.opacity(0.1))
                                )
                        }
                    }
                }
            }

            // Fail notes (if failed)
            if result.status == .failed && !result.failNotes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                    Text(result.failNotes)
                        .font(.system(size: 12))
                        .lineLimit(2)
                }
                .foregroundColor(NooberTheme.error)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(NooberTheme.error.opacity(0.08))
                )
            }

            // Attached requests count (if failed)
            if result.status == .failed && !result.attachedRequestIds.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 11))
                    Text("\(result.attachedRequestIds.count) API call\(result.attachedRequestIds.count == 1 ? "" : "s") attached")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.secondary)
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                if result.status == .pending {
                    actionButton("Pass", icon: "checkmark.circle.fill", color: NooberTheme.success) {
                        NooberTheme.hapticSuccess()
                        withAnimation(.spring(response: 0.3)) {
                            store.markPassed(id: result.id)
                        }
                    }
                    actionButton("Fail", icon: "xmark.circle.fill", color: NooberTheme.error) {
                        NooberTheme.hapticError()
                        failingItem = result
                    }
                } else {
                    actionButton("Reset", icon: "arrow.counterclockwise", color: .secondary) {
                        NooberTheme.hapticLight()
                        withAnimation(.spring(response: 0.3)) {
                            store.resetItem(id: result.id)
                        }
                    }
                    if result.status == .failed {
                        actionButton("Share Bug", icon: "square.and.arrow.up", color: NooberTheme.accent) {
                            shareBugReport(for: result)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(statusBorderColor(result.status), lineWidth: result.status == .pending ? 0 : 1.5)
        )
    }

    // MARK: - Helpers

    private func priorityBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }

    private func statusIcon(_ status: QAChecklistStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            case .passed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(NooberTheme.success)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(NooberTheme.error)
            }
        }
        .font(.system(size: 20))
    }

    private func statusBorderColor(_ status: QAChecklistStatus) -> Color {
        switch status {
        case .pending: return .clear
        case .passed: return NooberTheme.success.opacity(0.4)
        case .failed: return NooberTheme.error.opacity(0.4)
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 13))
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(NooberTheme.PressScale())
    }

    // MARK: - Share Full Report

    private var shareFullReportButton: some View {
        Button { shareFullReport() } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                Text("Share Full Report")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(NooberTheme.accent)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 80, height: 80)
                Image(systemName: "checklist")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text("No checklist registered")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Register a checklist in your app:\nNoober.shared.registerChecklist([...])")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Share

    private func shareBugReport(for result: QAChecklistResult) {
        let text = QAReportGenerator.bugReport(for: result, buildNumber: store.buildNumber)
        presentShareSheet(text: text)
    }

    private func shareFullReport() {
        let text = QAReportGenerator.fullReport(
            results: store.sortedResults,
            buildNumber: store.buildNumber,
            passed: store.passedCount,
            failed: store.failedCount,
            pending: store.pendingCount
        )
        presentShareSheet(text: text)
    }

    private func presentShareSheet(text: String) {
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            let topWindow = scene.windows
                .filter { !$0.isHidden }
                .sorted(by: { $0.windowLevel.rawValue < $1.windowLevel.rawValue })
                .last
            var vc = topWindow?.rootViewController
            while let presented = vc?.presentedViewController {
                vc = presented
            }
            vc?.present(av, animated: true)
        }
    }
}

// MARK: - Report Generator

@MainActor
enum QAReportGenerator {

    static func bugReport(for result: QAChecklistResult, buildNumber: String) -> String {
        var lines: [String] = []

        lines.append("Bug Report - \(appName()) v\(appVersion()) (\(buildNumber))")
        lines.append(String(repeating: "=", count: 40))
        lines.append("")
        lines.append("Item: \(result.title)")
        lines.append("Status: FAILED")
        lines.append("Priority: \(result.priority.rawValue)")
        if !result.notes.isEmpty {
            lines.append("Description: \(result.notes)")
        }
        lines.append("")

        if !result.failNotes.isEmpty {
            lines.append("-- Failure Notes --")
            lines.append(result.failNotes)
            lines.append("")
        }

        lines.append("-- Device Info --")
        lines.append("App: \(appName()) \(appVersion()) (\(buildNumber))")
        lines.append("Device: \(deviceModel())")
        lines.append("OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        lines.append("Locale: \(Locale.current.identifier)")
        lines.append("Timezone: \(TimeZone.current.identifier)")
        lines.append("")

        if !result.attachedRequestIds.isEmpty {
            let requests = NetworkActivityStore.shared.requests.filter {
                result.attachedRequestIds.contains($0.id)
            }
            if !requests.isEmpty {
                lines.append("-- Attached API Calls (\(requests.count)) --")
                for req in requests {
                    let status = req.statusCode.map(String.init) ?? "ERR"
                    lines.append("\(req.method) \(req.url)")
                    lines.append("  Status: \(status) | Duration: \(req.durationText)")
                    if let error = req.errorDescription {
                        lines.append("  Error: \(error)")
                    }
                    lines.append("")
                }
            }
        }

        if !result.endpoints.isEmpty {
            lines.append("-- Tagged Endpoints --")
            for ep in result.endpoints {
                lines.append("  \(ep)")
            }
        }

        return lines.joined(separator: "\n")
    }

    static func fullReport(
        results: [QAChecklistResult],
        buildNumber: String,
        passed: Int,
        failed: Int,
        pending: Int
    ) -> String {
        var lines: [String] = []

        lines.append("QA Report - \(appName()) v\(appVersion()) (\(buildNumber))")
        lines.append(String(repeating: "=", count: 40))
        lines.append("")
        lines.append("Device: \(deviceModel()) | \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
        lines.append("Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))")
        lines.append("")
        lines.append("Summary: \(results.count) items | \(passed) passed | \(failed) failed | \(pending) pending")
        lines.append("")

        for result in results {
            let icon: String
            switch result.status {
            case .passed: icon = "[PASS]"
            case .failed: icon = "[FAIL]"
            case .pending: icon = "[    ]"
            }

            lines.append("\(icon) \(result.title)")
            if result.priority == .high {
                lines.append("  Priority: HIGH")
            }
            if result.status == .failed && !result.failNotes.isEmpty {
                lines.append("  Notes: \(result.failNotes)")
            }
            if result.status == .failed && !result.attachedRequestIds.isEmpty {
                lines.append("  Attached API calls: \(result.attachedRequestIds.count)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func appName() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    }

    private static func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "Unknown"
            }
        }
        if machine.hasPrefix("x86_64") || machine.hasPrefix("arm64") {
            return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? machine
        }
        return machine
    }
}
