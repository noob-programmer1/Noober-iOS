import SwiftUI

struct QAFailReportSheet: View {

    let item: QAChecklistResult
    @ObservedObject var store: QAChecklistStore

    @Environment(\.dismiss) private var dismiss
    @StateObject private var networkStore = NetworkActivityStore.shared

    @State private var failNotes = ""
    @State private var selectedRequestIds: Set<UUID> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                itemHeader
                notesSection
                Divider()
                apiCallPicker
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") { submitFail() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(NooberTheme.error)
                }
            }
            .navigationTitle("Report Failure")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
        .onAppear { autoSelectRequests() }
    }

    // MARK: - Item Header

    private var itemHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if item.priority == .high {
                    Text("HIGH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(NooberTheme.error)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(NooberTheme.error.opacity(0.12))
                        )
                }
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
            }
            if !item.notes.isEmpty {
                Text(item.notes)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FAILURE NOTES")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(NooberTheme.accent)
                .padding(.horizontal, 4)

            TextEditor(text: $failNotes)
                .font(.system(size: 14))
                .frame(minHeight: 80, maxHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                )
        }
        .padding(16)
    }

    // MARK: - API Call Picker

    private var apiCallPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("ATTACH API CALLS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(NooberTheme.accent)
                Spacer()
                Text("\(selectedRequestIds.count) selected")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if networkStore.requests.isEmpty {
                Text("No network requests captured yet.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(networkStore.requests) { request in
                            apiCallRow(request)
                            Divider().padding(.leading, 42)
                        }
                    }
                }
            }
        }
    }

    private func apiCallRow(_ request: NetworkRequestModel) -> some View {
        let isSelected = selectedRequestIds.contains(request.id)

        return Button {
            if isSelected {
                selectedRequestIds.remove(request.id)
            } else {
                selectedRequestIds.insert(request.id)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? NooberTheme.accent : Color(uiColor: .tertiaryLabel))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(request.method)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(NooberTheme.methodColor(request.method))
                        if let code = request.statusCode {
                            Text("\(code)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(code >= 400 ? NooberTheme.error : (code >= 300 ? NooberTheme.warning : NooberTheme.success))
                        }
                        Spacer()
                        Text(request.durationText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Text(request.path)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(request.host)
                        .font(.system(size: 10))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? NooberTheme.accent.opacity(0.06) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Auto-Select

    private func autoSelectRequests() {
        let twoMinutesAgo = Date().addingTimeInterval(-120)

        for request in networkStore.requests {
            var shouldSelect = false

            // Error responses (4xx / 5xx)
            if let code = request.statusCode, code >= 400 {
                shouldSelect = true
            }

            // Connection failures (no status code + error)
            if request.statusCode == nil && request.errorDescription != nil {
                shouldSelect = true
            }

            // URL matches tagged endpoints
            for endpoint in item.endpoints {
                if request.url.contains(endpoint) || request.path.contains(endpoint) {
                    shouldSelect = true
                    break
                }
            }

            // Last 2 minutes
            if request.timestamp >= twoMinutesAgo {
                shouldSelect = true
            }

            if shouldSelect {
                selectedRequestIds.insert(request.id)
            }
        }
    }

    // MARK: - Submit

    private func submitFail() {
        store.markFailed(
            id: item.id,
            notes: failNotes,
            requestIds: Array(selectedRequestIds)
        )
        dismiss()
    }
}
