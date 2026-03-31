import SwiftUI
import UIKit

// MARK: - Network Panel (Proxyman-inspired)

struct V2NetworkPanel: View {

    @StateObject private var store = NetworkActivityStore.shared
    @State private var searchText = ""
    @State private var selectedMethods: Set<String> = []
    @State private var selectedStatuses: Set<NetworkRequestModel.StatusCodeCategory> = []
    @State private var selectedEntryType: NetworkEntryType?
    @State private var selectedRequest: NetworkRequestModel?

    // MARK: - Computed

    private var filteredEntries: [NetworkEntry] {
        store.allEntries.filter { entry in
            if let type = selectedEntryType, entry.entryType != type { return false }

            switch entry {
            case .http(let req):
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matches = req.url.lowercased().contains(q)
                        || req.method.lowercased().contains(q)
                        || req.host.lowercased().contains(q)
                        || req.path.lowercased().contains(q)
                        || (req.statusCode.map { String($0) } ?? "").contains(q)
                    if !matches { return false }
                }
                if !selectedMethods.isEmpty && !selectedMethods.contains(req.method) { return false }
                if !selectedStatuses.isEmpty && !selectedStatuses.contains(req.statusCodeCategory) { return false }
                return true

            case .webSocket(let conn):
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matches = conn.url.lowercased().contains(q) || conn.host.lowercased().contains(q)
                    if !matches { return false }
                }
                if !selectedMethods.isEmpty || !selectedStatuses.isEmpty { return false }
                return true
            }
        }
    }

    private var stats: (total: Int, ok: Int, fail: Int, ws: Int) {
        let ok = store.requests.filter(\.isSuccess).count
        return (store.requests.count, ok, store.requests.count - ok, store.webSocketConnections.count)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Search + controls
            toolbar
            // Filter chips
            filterStrip
            // Stats bar
            statsBar
            V2Separator()

            // Content
            if filteredEntries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .background(DS.Background.primary)
        .sheet(item: $selectedRequest) { req in
            V2NetworkDetail(request: req)
                .darkContainer()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: DS.Space.m) {
            V2SearchField(text: $searchText, placeholder: "Filter requests...")

            if store.activeRequestCount > 0 {
                HStack(spacing: DS.Space.s) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(DS.Accent.primary)
                    Text("\(store.activeRequestCount)")
                        .font(DS.Font.mono(11, weight: .bold))
                        .foregroundColor(DS.Accent.primary)
                }
            }

            if !store.requests.isEmpty || !store.webSocketConnections.isEmpty {
                V2ToolbarButton(icon: "trash", color: DS.Status.error.opacity(0.7)) {
                    withAnimation(DS.snappy) { store.clearAll() }
                }
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
    }

    // MARK: - Filter Strip

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.s) {
                // Type filters
                V2FilterChip(title: "All", isSelected: selectedEntryType == nil) {
                    selectedEntryType = nil
                }
                V2FilterChip(title: "HTTP", isSelected: selectedEntryType == .http, count: store.requests.count) {
                    selectedEntryType = selectedEntryType == .http ? nil : .http
                }
                V2FilterChip(title: "WS", isSelected: selectedEntryType == .webSocket, count: store.webSocketConnections.count) {
                    selectedEntryType = selectedEntryType == .webSocket ? nil : .webSocket
                }

                // Divider
                Rectangle().fill(DS.Border.subtle).frame(width: 1, height: 16)

                // Status filters
                ForEach(NetworkRequestModel.StatusCodeCategory.allCases, id: \.self) { cat in
                    let count = store.requests.filter { $0.statusCodeCategory == cat }.count
                    if count > 0 {
                        V2FilterChip(
                            title: cat.rawValue,
                            isSelected: selectedStatuses.contains(cat),
                            count: count
                        ) {
                            if selectedStatuses.contains(cat) { selectedStatuses.remove(cat) }
                            else { selectedStatuses.insert(cat) }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.s)
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: DS.Space.l) {
            statsLabel("\(stats.total)", "total", DS.Text.primary)
            statsLabel("\(stats.ok)", "ok", DS.Status.success)
            statsLabel("\(stats.fail)", "err", DS.Status.error)
            statsLabel("\(stats.ws)", "ws", DS.Status.purple)
            Spacer()
            Text("\(filteredEntries.count) shown")
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.tertiary)
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.s + 2)
        .background(DS.Background.elevated)
    }

    private func statsLabel(_ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: DS.Space.xs) {
            Text(value)
                .font(DS.Font.mono(12, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(DS.Font.monoMicro)
                .foregroundColor(DS.Text.tertiary)
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredEntries, id: \.id) { entry in
                    switch entry {
                    case .http(let req):
                        V2HTTPRow(request: req)
                            .onTapGesture {
                                DS.haptic()
                                selectedRequest = req
                            }
                    case .webSocket(let conn):
                        V2WebSocketRow(connection: conn)
                    }
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        V2EmptyState(
            icon: store.requests.isEmpty && store.webSocketConnections.isEmpty
                ? "antenna.radiowaves.left.and.right.slash"
                : "line.3.horizontal.decrease",
            title: store.requests.isEmpty && store.webSocketConnections.isEmpty
                ? "No traffic yet"
                : "No matching entries",
            subtitle: store.requests.isEmpty && store.webSocketConnections.isEmpty
                ? "Network requests will appear here"
                : "Try adjusting filters"
        )
    }
}

// MARK: - HTTP Row (Dense, Proxyman-style)

private struct V2HTTPRow: View {
    let request: NetworkRequestModel

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Left: thin status bar
            Rectangle()
                .fill(DS.statusCodeColor(request.statusCode))
                .frame(width: 3)

            HStack(spacing: DS.Space.m) {
                // Method + Status
                VStack(spacing: DS.Space.xs) {
                    V2MethodBadge(method: request.method)
                    V2StatusBadge(code: request.statusCode)
                }
                .frame(width: 44)

                // Path + host
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    HStack(spacing: DS.Space.s) {
                        Text(request.path)
                            .font(DS.Font.mono(12, weight: .medium))
                            .foregroundColor(DS.Text.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        // Tags
                        if request.isMocked {
                            V2Tag(text: "MOCK", color: DS.Status.purple)
                        }
                        if request.originalURL != nil {
                            V2Tag(text: "RW", color: DS.Status.warning)
                        }
                        if request.isIntercepted {
                            V2Tag(text: "INT", color: DS.Status.warning)
                        }
                    }

                    HStack(spacing: DS.Space.s) {
                        Text(request.host)
                            .font(DS.Font.monoMicro)
                            .foregroundColor(DS.Text.tertiary)
                            .lineLimit(1)
                        if let screen = request.screenName {
                            Text("·")
                                .foregroundColor(DS.Text.disabled)
                            Text(screen)
                                .font(DS.Font.monoMicro)
                                .foregroundColor(DS.Text.tertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Right: timing + size + timestamp
                VStack(alignment: .trailing, spacing: DS.Space.xs) {
                    V2Duration(duration: request.duration)
                    Text(request.responseSizeText)
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.tertiary)
                    Text(Self.timeFormatter.string(from: request.timestamp))
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.disabled)
                }
            }
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
        }
        .background(DS.Background.primary)
        .overlay(alignment: .bottom) {
            V2Separator(leading: 47)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - WebSocket Row

private struct V2WebSocketRow: View {
    let connection: WebSocketConnectionModel

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private var statusColor: Color {
        switch connection.status {
        case .connecting:   return DS.Status.warning
        case .connected:    return DS.Status.success
        case .disconnected: return DS.Text.tertiary
        case .error:        return DS.Status.error
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(DS.Status.purple)
                .frame(width: 3)

            HStack(spacing: DS.Space.m) {
                VStack(spacing: DS.Space.xs) {
                    V2Tag(text: "WS", color: DS.Status.purple)
                    StatusDot(color: statusColor)
                }
                .frame(width: 44)

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(connection.displayName)
                        .font(DS.Font.mono(12, weight: .medium))
                        .foregroundColor(DS.Text.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: DS.Space.m) {
                        Text(connection.host)
                            .font(DS.Font.monoMicro)
                            .foregroundColor(DS.Text.tertiary)
                        HStack(spacing: DS.Space.s) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(connection.sentCount)")
                                .font(DS.Font.monoMicro)
                        }
                        .foregroundColor(DS.Status.warning)
                        HStack(spacing: DS.Space.s) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8, weight: .bold))
                            Text("\(connection.receivedCount)")
                                .font(DS.Font.monoMicro)
                        }
                        .foregroundColor(DS.Status.info)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DS.Space.xs) {
                    Text("\(connection.frames.count) frames")
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.tertiary)
                    Text(Self.timeFormatter.string(from: connection.lastActivityTime))
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.disabled)
                }
            }
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
        }
        .background(DS.Background.primary)
        .overlay(alignment: .bottom) {
            V2Separator(leading: 47)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Network Detail (Inspector View)

struct V2NetworkDetail: View {

    let request: NetworkRequestModel
    @State private var activeTab = 0
    @State private var searchText = ""
    @State private var copiedField: String?
    @State private var bodyViewMode = 0 // 0 = list, 1 = raw
    @State private var isBodyExpanded = false
    @Environment(\.dismiss) private var dismiss

    private var curlCommand: String { CURLGenerator.generate(from: request) }

    private var requestBodyKV: [JSONFlattener.KeyValue] {
        guard let body = request.requestBody else { return [] }
        return JSONFlattener.flatten(body)
    }

    private var responseBodyKV: [JSONFlattener.KeyValue] {
        guard let body = request.responseBody else { return [] }
        return JSONFlattener.flatten(body)
    }

    var body: some View {
        VStack(spacing: 0) {
            detailTopBar
            headerSummary
            tabPicker
            V2Separator()
            tabContent
        }
        .background(DS.Background.primary)
    }

    // MARK: - Top Bar

    private var detailTopBar: some View {
        HStack(spacing: DS.Space.m) {
            Button {
                DS.haptic()
                dismiss()
            } label: {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Close")
                        .font(DS.Font.caption)
                }
                .foregroundColor(DS.Accent.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(request.path)
                .font(DS.Font.monoSmall)
                .foregroundColor(DS.Text.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Menu {
                Button { replayRequest() } label: { Label("Quick Replay", systemImage: "paperplane") }
                Divider()
                Button { copyDetails() } label: { Label("Copy Details", systemImage: "doc.on.doc") }
                Button { copyCurl() } label: { Label("Copy cURL", systemImage: "terminal") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 16))
                    .foregroundColor(DS.Text.secondary)
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.m)
        .background(DS.Background.elevated)
    }

    // MARK: - Header Summary

    private var headerSummary: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            // Badges row
            HStack(spacing: DS.Space.m) {
                V2MethodBadge(method: request.method)
                V2StatusBadge(code: request.statusCode)
                V2Tag(text: request.contentType.rawValue, color: DS.Text.secondary)

                if request.isMocked { V2Tag(text: "MOCK", color: DS.Status.purple) }
                if request.isIntercepted { V2Tag(text: "INT", color: DS.Status.warning) }
                if request.isEnvironmentRewritten { V2Tag(text: "ENV", color: DS.Status.success) }

                Spacer()

                V2Duration(duration: request.duration)

                Text(request.responseSizeText)
                    .font(DS.Font.monoMicro)
                    .foregroundColor(DS.Text.tertiary)
            }

            // Full URL
            Text(request.url)
                .font(DS.Font.monoSmall)
                .foregroundColor(DS.Text.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            // Error banner
            if let error = request.errorDescription {
                HStack(spacing: DS.Space.s) {
                    StatusDot(color: DS.Status.error)
                    Text(error)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Status.error)
                }
                .padding(DS.Space.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.s)
                        .fill(DS.Status.error.opacity(0.1))
                )
            }

            // Rewrite info
            if let original = request.originalURL {
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 10))
                    Text(original)
                        .font(DS.Font.monoMicro)
                        .lineLimit(1)
                }
                .foregroundColor(DS.Status.warning)
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.l)
        .background(DS.Background.elevated)
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton("Overview", index: 0)
            tabButton("Request", index: 1)
            tabButton("Response", index: 2)
            tabButton("cURL", index: 3)
        }
        .background(DS.Background.elevated)
    }

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            DS.haptic()
            withAnimation(DS.snappy) { activeTab = index }
        } label: {
            VStack(spacing: DS.Space.s) {
                Text(title)
                    .font(DS.Font.caption)
                    .foregroundColor(activeTab == index ? DS.Accent.primary : DS.Text.secondary)
                    .padding(.horizontal, DS.Space.l)
                    .padding(.top, DS.Space.m)

                Rectangle()
                    .fill(activeTab == index ? DS.Accent.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            switch activeTab {
            case 0: overviewContent
            case 1: requestContent
            case 2: responseContent
            case 3: curlContent
            default: EmptyView()
            }
        }
    }

    // MARK: - Overview

    private var overviewContent: some View {
        VStack(spacing: 0) {
            sectionHeader("General")
            V2KeyValueRow(key: "Method", value: request.method, valueColor: DS.methodColor(request.method))
            V2KeyValueRow(key: "Host", value: request.host)
            V2KeyValueRow(key: "Path", value: request.path)
            V2KeyValueRow(key: "Status", value: request.statusCode.map(String.init) ?? "---",
                          valueColor: DS.statusCodeColor(request.statusCode))
            V2KeyValueRow(key: "URL", value: request.url)

            sectionHeader("Timing")
            V2KeyValueRow(key: "Duration", value: request.durationText)
            V2KeyValueRow(key: "Size", value: request.responseSizeText)
            V2KeyValueRow(key: "MIME", value: request.mimeType ?? "---")
            V2KeyValueRow(key: "Type", value: request.contentType.rawValue)

            if let queryItems = queryParams, !queryItems.isEmpty {
                sectionHeader("Query (\(queryItems.count))")
                ForEach(queryItems, id: \.0) { key, value in
                    V2KeyValueRow(key: key, value: value)
                }
            }
        }
    }

    // MARK: - Request

    private var requestContent: some View {
        VStack(spacing: 0) {
            sectionHeader("Headers (\(request.requestHeaders.count))")
            if request.requestHeaders.isEmpty {
                emptyLabel("No request headers")
            } else {
                ForEach(request.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    V2KeyValueRow(key: key, value: value)
                }
            }

            sectionHeader("Body")
            if let body = request.requestBody, !body.isEmpty {
                bodySection(data: body, prettyText: request.prettyRequestBody, kvItems: requestBodyKV)
            } else {
                emptyLabel("No request body")
            }
        }
    }

    // MARK: - Response

    private var responseContent: some View {
        VStack(spacing: 0) {
            // Image preview
            if request.isImage, let img = request.responseImage {
                sectionHeader("Preview")
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.s))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .stroke(DS.Border.subtle, lineWidth: 0.5)
                    )
                    .padding(.horizontal, DS.Space.xl)
                    .padding(.vertical, DS.Space.m)
            }

            sectionHeader("Headers (\(request.responseHeaders.count))")
            if request.responseHeaders.isEmpty {
                emptyLabel("No response headers")
            } else {
                ForEach(request.responseHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    V2KeyValueRow(key: key, value: value)
                }
            }

            sectionHeader("Body")
            if let body = request.responseBody, !body.isEmpty {
                if request.isImage {
                    emptyLabel("Image data — \(request.responseSizeText)")
                } else {
                    bodySection(data: body, prettyText: request.prettyResponseBody, kvItems: responseBodyKV)
                }
            } else {
                emptyLabel("No response body")
            }
        }
    }

    // MARK: - cURL

    private var curlContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated cURL")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Text.tertiary)
                Spacer()
                copyButton("cURL") {
                    UIPasteboard.general.string = curlCommand
                }
            }
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)

            ScrollView([.horizontal, .vertical]) {
                Text(curlCommand)
                    .font(DS.Font.monoSmall)
                    .foregroundColor(DS.Accent.primary)
                    .textSelection(.enabled)
                    .padding(DS.Space.xl)
            }
        }
    }

    // MARK: - Body Section (List/Raw)

    private func bodySection(data: Data, prettyText: String, kvItems: [JSONFlattener.KeyValue]) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            // Mode picker + copy
            HStack(spacing: DS.Space.m) {
                if !kvItems.isEmpty {
                    HStack(spacing: 0) {
                        bodyModeButton("List", index: 0)
                        bodyModeButton("Raw", index: 1)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.s)
                            .fill(DS.Background.surface)
                    )
                }
                Spacer()
                copyButton("body") {
                    UIPasteboard.general.string = prettyText
                }
            }
            .padding(.horizontal, DS.Space.xl)

            if bodyViewMode == 0 && !kvItems.isEmpty {
                // List view
                ForEach(kvItems) { item in
                    kvItemRow(item)
                }
            } else {
                // Raw view
                ScrollView(.horizontal, showsIndicators: true) {
                    Text(prettyText)
                        .font(DS.Font.monoSmall)
                        .foregroundColor(DS.Text.primary)
                        .textSelection(.enabled)
                        .padding(.horizontal, DS.Space.xl)
                }
                .frame(maxHeight: isBodyExpanded ? .infinity : 400)

                if prettyText.components(separatedBy: "\n").count > 15 {
                    Button {
                        withAnimation(DS.smooth) { isBodyExpanded.toggle() }
                    } label: {
                        HStack(spacing: DS.Space.s) {
                            Image(systemName: isBodyExpanded ? "chevron.up" : "chevron.down")
                            Text(isBodyExpanded ? "Collapse" : "Expand")
                        }
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Accent.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Space.m)
                        .background(DS.Accent.subtle)
                        .cornerRadius(DS.Radius.s)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.Space.xl)
                }
            }
        }
        .padding(.bottom, DS.Space.l)
    }

    private func bodyModeButton(_ title: String, index: Int) -> some View {
        Button {
            DS.haptic()
            withAnimation(DS.snappy) { bodyViewMode = index }
        } label: {
            Text(title)
                .font(DS.Font.micro)
                .foregroundColor(bodyViewMode == index ? DS.Accent.primary : DS.Text.tertiary)
                .padding(.horizontal, DS.Space.l)
                .padding(.vertical, DS.Space.s)
                .background(
                    bodyViewMode == index
                        ? RoundedRectangle(cornerRadius: DS.Radius.xs).fill(DS.Accent.subtle)
                        : nil
                )
        }
        .buttonStyle(.plain)
    }

    private func kvItemRow(_ item: JSONFlattener.KeyValue) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Depth guides
            if item.depth > 0 {
                ForEach(0..<item.depth, id: \.self) { _ in
                    Rectangle()
                        .fill(DS.Accent.primary.opacity(0.1))
                        .frame(width: 1)
                        .padding(.trailing, DS.Space.m)
                }
            }

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(item.key)
                    .font(DS.Font.mono(10, weight: .semibold))
                    .foregroundColor(item.isLeaf ? DS.Text.secondary : DS.Accent.primary)

                if item.isLeaf {
                    Text(item.value)
                        .font(DS.Font.monoSmall)
                        .foregroundColor(jsonValueColor(item.value))
                } else {
                    Text(item.value)
                        .font(DS.Font.monoMicro)
                        .foregroundColor(DS.Text.disabled)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, DS.Space.xs + 1)
        .padding(.horizontal, DS.Space.xl)
        .contentShape(Rectangle())
        .onTapGesture {
            UIPasteboard.general.string = item.isLeaf ? "\(item.key): \(item.value)" : item.key
            flash(item.id)
        }
        .modifier(CopyFlash(isActive: copiedField == item.id))
        .overlay(alignment: .bottom) {
            V2Separator(leading: CGFloat(item.depth) * 10 + DS.Space.xl)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        V2SectionHeader(title)
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(DS.Font.caption)
            .foregroundColor(DS.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Space.xl)
            .padding(.vertical, DS.Space.l)
    }

    private func copyButton(_ field: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            flash(field)
        } label: {
            HStack(spacing: DS.Space.s) {
                Image(systemName: copiedField == field ? "checkmark" : "doc.on.doc")
                Text(copiedField == field ? "Copied" : "Copy")
            }
            .font(DS.Font.micro)
            .foregroundColor(copiedField == field ? DS.Status.success : DS.Accent.primary)
            .padding(.horizontal, DS.Space.m)
            .padding(.vertical, DS.Space.s)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xs)
                    .fill((copiedField == field ? DS.Status.success : DS.Accent.primary).opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private var queryParams: [(String, String)]? {
        guard let url = URL(string: request.url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty else { return nil }
        return items.map { ($0.name, $0.value ?? "") }
    }

    private func jsonValueColor(_ value: String) -> Color {
        switch value.lowercased() {
        case "null":  return DS.Text.disabled
        case "true":  return DS.Status.success
        case "false": return DS.Status.error
        default:
            if Double(value) != nil { return DS.Status.info }
            return DS.Text.primary
        }
    }

    private func flash(_ field: String) {
        DS.hapticNotify(.success)
        withAnimation(DS.snappy) { copiedField = field }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { copiedField = nil }
        }
    }

    private func replayRequest() {
        RequestReplayer.replay(from: request)
        DS.hapticNotify(.success)
    }

    private func copyDetails() {
        let text = """
        \(request.method) \(request.url)
        Status: \(request.statusCode.map(String.init) ?? "---")
        Duration: \(request.durationText)
        Size: \(request.responseSizeText)

        --- Request Headers ---
        \(request.requestHeaders.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))

        --- Request Body ---
        \(request.prettyRequestBody)

        --- Response Headers ---
        \(request.responseHeaders.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))

        --- Response Body ---
        \(request.prettyResponseBody)
        """
        UIPasteboard.general.string = text
        flash("details")
    }

    private func copyCurl() {
        UIPasteboard.general.string = curlCommand
        flash("curl")
    }
}
