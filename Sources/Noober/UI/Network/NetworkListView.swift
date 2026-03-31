import SwiftUI

struct NetworkListView: View {

    @ObservedObject var store: NetworkActivityStore
    @State private var searchText = ""
    @State private var selectedMethods: Set<String> = []
    @State private var selectedStatuses: Set<NetworkRequestModel.StatusCodeCategory> = []
    @State private var selectedHosts: Set<String> = []
    @State private var selectedEntryType: NetworkEntryType?
    @State private var showFilterSheet = false
    @State private var replayingRequest: NetworkRequestModel?
    @State private var createMockRequest: NetworkRequestModel?
    @State private var createInterceptRequest: NetworkRequestModel?
    @State private var groupByScreen = false
    @State private var selectedScreens: Set<String> = []
    @State private var webViewOnly = false

    // MARK: - Computed

    private var uniqueMethods: [String] {
        Array(Set(store.requests.map(\.method))).sorted()
    }

    private var uniqueHosts: [String] {
        let httpHosts = store.requests.map(\.host)
        let wsHosts = store.webSocketConnections.map(\.host)
        return Array(Set(httpHosts + wsHosts)).sorted()
    }

    private var activeFilterCount: Int {
        selectedMethods.count + selectedStatuses.count + selectedHosts.count
            + selectedScreens.count + (selectedEntryType != nil ? 1 : 0)
            + (webViewOnly ? 1 : 0)
    }

    private var webViewCount: Int {
        store.requests.filter(\.isWebView).count
    }

    private var filteredEntries: [NetworkEntry] {
        store.allEntries.filter { entry in
            // Type filter
            if let type = selectedEntryType, entry.entryType != type { return false }

            // WebView filter
            if webViewOnly && !entry.isWebView { return false }

            // Host filter
            if !selectedHosts.isEmpty && !selectedHosts.contains(entry.host) { return false }

            // Screen filter
            if !selectedScreens.isEmpty {
                let screen = entry.screenName ?? "Unknown"
                if !selectedScreens.contains(screen) { return false }
            }

            switch entry {
            case .http(let req):
                // Search
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matchesAny = req.url.lowercased().contains(q)
                        || req.method.lowercased().contains(q)
                        || req.host.lowercased().contains(q)
                        || req.path.lowercased().contains(q)
                        || (req.statusCode.map { String($0) } ?? "").contains(q)
                        || req.contentType.rawValue.lowercased().contains(q)
                    if !matchesAny { return false }
                }
                // Method
                if !selectedMethods.isEmpty && !selectedMethods.contains(req.method) { return false }
                // Status
                if !selectedStatuses.isEmpty && !selectedStatuses.contains(req.statusCodeCategory) { return false }
                return true

            case .webSocket(let conn):
                if !searchText.isEmpty {
                    let q = searchText.lowercased()
                    let matchesAny = conn.url.lowercased().contains(q)
                        || conn.host.lowercased().contains(q)
                        || "websocket".contains(q) || "ws".contains(q)
                    if !matchesAny { return false }
                }
                // Method/status filters don't apply to WS
                if !selectedMethods.isEmpty || !selectedStatuses.isEmpty { return false }
                return true
            }
        }
    }

    private var httpStats: (total: Int, success: Int, failed: Int) {
        let total = store.requests.count
        let success = store.requests.filter(\.isSuccess).count
        return (total, success, total - success)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            searchAndFilterBar
            if activeFilterCount > 0 { activeFiltersRow }
            typeAndStatusChips
            if !store.requests.isEmpty || !store.webSocketConnections.isEmpty {
                statsBar
                Divider()
            }
            if filteredEntries.isEmpty { emptyState }
            else if groupByScreen { groupedEntryList }
            else { entryList }
        }
    }

    // MARK: - Search + Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("Search URL, method, host...", text: $searchText)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button {
                        NooberTheme.hapticLight()
                        withAnimation(.easeInOut(duration: 0.15)) { searchText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(uiColor: .tertiarySystemFill)))

            // Filter button
            Button { showFilterSheet = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundColor(activeFilterCount > 0 ? NooberTheme.accent : .secondary)
                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(NooberTheme.accent))
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    methods: uniqueMethods, hosts: uniqueHosts,
                    hasWebViewRequests: webViewCount > 0,
                    selectedMethods: $selectedMethods, selectedStatuses: $selectedStatuses,
                    selectedHosts: $selectedHosts, webViewOnly: $webViewOnly
                )
            }

            // Trash
            if !store.requests.isEmpty || !store.webSocketConnections.isEmpty {
                Button {
                    NooberTheme.hapticMedium()
                    withAnimation(.spring(response: 0.3)) { store.clearAll() }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(NooberTheme.error.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    // MARK: - Active Filters

    private var activeFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let type = selectedEntryType {
                    activeTag(type.rawValue, color: type == .webSocket ? NooberTheme.webSocket : NooberTheme.accent) {
                        selectedEntryType = nil
                    }
                }
                if webViewOnly {
                    activeTag("WebView", color: .purple) { webViewOnly = false }
                }
                ForEach(Array(selectedMethods).sorted(), id: \.self) { m in
                    activeTag(m, color: NooberTheme.methodColor(m)) { selectedMethods.remove(m) }
                }
                ForEach(Array(selectedStatuses).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { s in
                    activeTag(s.rawValue, color: NooberTheme.statusColor(s)) { selectedStatuses.remove(s) }
                }
                ForEach(Array(selectedHosts).sorted(), id: \.self) { h in
                    activeTag(h, color: .secondary) { selectedHosts.remove(h) }
                }
                ForEach(Array(selectedScreens).sorted(), id: \.self) { s in
                    activeTag(s, color: NooberTheme.accent) { selectedScreens.remove(s) }
                }
                Button {
                    NooberTheme.hapticLight()
                    withAnimation(.spring(response: 0.25)) {
                        selectedEntryType = nil; webViewOnly = false
                        selectedMethods.removeAll(); selectedStatuses.removeAll(); selectedHosts.removeAll()
                        selectedScreens.removeAll()
                    }
                } label: {
                    Text("Clear all").font(.system(size: 11, weight: .medium)).foregroundColor(NooberTheme.accent)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
        }
    }

    private func activeTag(_ text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 3) {
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundColor(color).lineLimit(1)
            Button { withAnimation(.spring(response: 0.25)) { onRemove() } } label: {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(color.opacity(0.6))
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.12)))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Type + Status Chips

    private var typeAndStatusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Type chips
                FilterChip(title: "All", isSelected: selectedEntryType == nil) { selectedEntryType = nil }
                FilterChip(title: "HTTP (\(store.requests.count))", isSelected: selectedEntryType == .http) {
                    selectedEntryType = selectedEntryType == .http ? nil : .http
                }
                FilterChip(title: "WS (\(store.webSocketConnections.count))", isSelected: selectedEntryType == .webSocket) {
                    selectedEntryType = selectedEntryType == .webSocket ? nil : .webSocket
                }
                if webViewCount > 0 {
                    FilterChip(title: "WebView (\(webViewCount))", isSelected: webViewOnly) {
                        webViewOnly.toggle()
                    }
                }

                // Separator
                Rectangle().fill(Color(uiColor: .separator)).frame(width: 1, height: 20)

                // Status chips (only relevant for HTTP)
                ForEach(NetworkRequestModel.StatusCodeCategory.allCases, id: \.self) { cat in
                    let count = store.requests.filter { $0.statusCodeCategory == cat }.count
                    if count > 0 {
                        FilterChip(title: "\(cat.rawValue) (\(count))", isSelected: selectedStatuses.contains(cat)) {
                            if selectedStatuses.contains(cat) { selectedStatuses.remove(cat) }
                            else { selectedStatuses.insert(cat) }
                        }
                    }
                }

                // Screen chips (group toggle + per-screen filters)
                if !store.uniqueScreenNames.isEmpty {
                    Rectangle().fill(Color(uiColor: .separator)).frame(width: 1, height: 20)

                    FilterChip(
                        title: groupByScreen ? "Grouped" : "Group by Screen",
                        isSelected: groupByScreen
                    ) {
                        withAnimation(.spring(response: 0.3)) { groupByScreen.toggle() }
                    }

                    ForEach(store.uniqueScreenNames, id: \.self) { screen in
                        FilterChip(title: screen, isSelected: selectedScreens.contains(screen)) {
                            if selectedScreens.contains(screen) { selectedScreens.remove(screen) }
                            else { selectedScreens.insert(screen) }
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
        }
    }

    // MARK: - Grouped Entry List

    private var groupedEntryList: some View {
        let groups = store.entriesGroupedByScreen(from: filteredEntries)
        return List {
            ForEach(groups, id: \.screen) { group in
                Section {
                    ForEach(group.entries, id: \.id) { entry in
                        switch entry {
                        case .http(let req):
                            NavigationLink(destination: NetworkDetailView(request: req)) {
                                HTTPRowView(request: req)
                            }
                            .contextMenu { httpContextMenu(req) }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                            .listRowSeparator(.hidden)
                        case .webSocket(let conn):
                            NavigationLink(destination: WebSocketDetailPlaceholder(connection: conn)) {
                                WebSocketRowView(connection: conn)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(NooberTheme.accent)
                        Text(group.screen)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(group.entries.count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(NooberTheme.accent.opacity(0.7)))
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.plain)
        .sheet(item: $replayingRequest) { req in
            ReplayEditView(request: req)
        }
        .sheet(item: $createMockRequest) { req in
            MockRuleEditView(store: RulesStore.shared, prefillFromRequest: req)
        }
        .sheet(item: $createInterceptRequest) { req in
            InterceptRuleEditView(store: RulesStore.shared, prefillFromRequest: req)
        }
    }

    @ViewBuilder
    private func httpContextMenu(_ req: NetworkRequestModel) -> some View {
        Button { replayingRequest = req } label: {
            Label("Replay...", systemImage: "arrow.clockwise")
        }
        Button { RequestReplayer.replay(from: req) } label: {
            Label("Quick Replay", systemImage: "paperplane")
        }
        Divider()
        Button { createMockRequest = req } label: {
            Label("Create Mock", systemImage: "wand.and.rays")
        }
        Button { createInterceptRequest = req } label: {
            Label("Create Intercept", systemImage: "hand.raised")
        }
        Divider()
        Button {
            UIPasteboard.general.string = CURLGenerator.generate(from: req)
            NooberTheme.hapticSuccess()
        } label: {
            Label("Copy cURL", systemImage: "terminal")
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statsItem(count: httpStats.total, label: "HTTP", color: .primary)
            statsItemDivider
            statsItem(count: httpStats.success, label: "OK", color: NooberTheme.success)
            statsItemDivider
            statsItem(count: httpStats.failed, label: "Fail", color: NooberTheme.error)
            statsItemDivider
            statsItem(count: store.webSocketConnections.count, label: "WS", color: NooberTheme.webSocket)

            Spacer()

            if store.activeRequestCount > 0 {
                HStack(spacing: 5) {
                    ProgressView().scaleEffect(0.65)
                    Text("\(store.activeRequestCount)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(NooberTheme.accent)
                }
                .padding(.trailing, 4)
            }

            Text("\(filteredEntries.count) shown")
                .font(.system(size: 11))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func statsItem(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(color)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
    }

    private var statsItemDivider: some View {
        Rectangle().fill(Color(uiColor: .separator)).frame(width: 1, height: 22).padding(.horizontal, 6)
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(filteredEntries, id: \.id) { entry in
                switch entry {
                case .http(let req):
                    NavigationLink(destination: NetworkDetailView(request: req)) {
                        HTTPRowView(request: req)
                    }
                    .contextMenu { httpContextMenu(req) }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)

                case .webSocket(let conn):
                    NavigationLink(destination: WebSocketDetailPlaceholder(connection: conn)) {
                        WebSocketRowView(connection: conn)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .sheet(item: $replayingRequest) { req in
            ReplayEditView(request: req)
        }
        .sheet(item: $createMockRequest) { req in
            MockRuleEditView(store: RulesStore.shared, prefillFromRequest: req)
        }
        .sheet(item: $createInterceptRequest) { req in
            InterceptRuleEditView(store: RulesStore.shared, prefillFromRequest: req)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color(uiColor: .tertiarySystemFill)).frame(width: 80, height: 80)
                Image(systemName: store.requests.isEmpty && store.webSocketConnections.isEmpty
                    ? "antenna.radiowaves.left.and.right.slash" : "line.3.horizontal.decrease")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            Text(store.requests.isEmpty && store.webSocketConnections.isEmpty ? "No traffic yet" : "No matching entries")
                .font(.system(size: 17, weight: .semibold)).foregroundColor(.secondary)
            Text(store.requests.isEmpty && store.webSocketConnections.isEmpty
                ? "Network requests and WebSocket\nconnections will appear here."
                : "Try adjusting your search or filters.")
                .font(.system(size: 14)).foregroundColor(Color(uiColor: .tertiaryLabel)).multilineTextAlignment(.center)
            if activeFilterCount > 0 {
                Button {
                    withAnimation {
                        searchText = ""; selectedEntryType = nil; webViewOnly = false
                        selectedMethods.removeAll(); selectedStatuses.removeAll(); selectedHosts.removeAll()
                        selectedScreens.removeAll()
                    }
                } label: {
                    Text("Clear Filters").font(.system(size: 14, weight: .medium)).foregroundColor(NooberTheme.accent)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(NooberTheme.accent.opacity(0.1)))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HTTP Row

private struct HTTPRowView: View {
    let request: NetworkRequestModel

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Status color strip
            RoundedRectangle(cornerRadius: 2)
                .fill(NooberTheme.statusColor(request.statusCodeCategory))
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                // Image thumbnail if response is an image
                if request.isImage, let img = request.responseImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                        )
                }

                VStack(alignment: .leading, spacing: 5) {
                    // Row 1: Badges
                    HStack(spacing: 4) {
                        MethodBadge(method: request.method)
                        StatusBadge(statusCode: request.statusCode, category: request.statusCodeCategory)
                        ContentTypeBadge(contentType: request.contentType)
                        if request.isMocked {
                            TypeBadge(text: "MOCK", color: NooberTheme.mock)
                        }
                        if request.originalURL != nil {
                            TypeBadge(text: "RW", color: NooberTheme.rewrite)
                        }
                        if request.isIntercepted {
                            TypeBadge(text: "INT", color: Color(red: 0.95, green: 0.55, blue: 0.15))
                        }
                        if request.isEnvironmentRewritten {
                            TypeBadge(text: "ENV", color: NooberTheme.success)
                        }
                        if request.isWebView {
                            TypeBadge(text: "WV", color: .purple)
                        }
                        Spacer()
                        DurationLabel(duration: request.duration)
                    }

                    // Row 2: Path
                    Text(request.path)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    // Row 3: Meta
                    HStack(spacing: 6) {
                        Text(request.host)
                            .lineLimit(1)
                        if let screen = request.screenName {
                            Text("·")
                            Text(screen)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(request.responseSizeText)
                        Text(Self.timeFormatter.string(from: request.timestamp))
                    }
                    .font(.system(size: 10))
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
        .padding(.leading, 16)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 30) }
    }
}

// MARK: - WebSocket Row

private struct WebSocketRowView: View {
    let connection: WebSocketConnectionModel

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Purple strip for WS
            RoundedRectangle(cornerRadius: 2)
                .fill(NooberTheme.webSocket)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 5) {
                // Row 1: WS badge + status
                HStack(spacing: 4) {
                    WebSocketBadge(status: connection.status)
                    Text(connection.status.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(NooberTheme.wsStatusColor(connection.status))
                    Spacer()
                    HStack(spacing: 8) {
                        Label("\(connection.sentCount)", systemImage: "arrow.up")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NooberTheme.warning)
                        Label("\(connection.receivedCount)", systemImage: "arrow.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(NooberTheme.info)
                    }
                }

                // Row 2: URL path
                Text(connection.displayName)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Row 3: Host + frame count + time
                HStack(spacing: 6) {
                    Text(connection.host).lineLimit(1)
                    Spacer()
                    Text("\(connection.frames.count) frames")
                    Text(Self.timeFormatter.string(from: connection.lastActivityTime))
                }
                .font(.system(size: 10))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
            .padding(.leading, 10)
            .padding(.vertical, 8)
        }
        .padding(.leading, 16)
        .overlay(alignment: .bottom) { Divider().padding(.leading, 30) }
    }
}

// MARK: - WS Detail Placeholder (to be built out later)

struct WebSocketDetailPlaceholder: View {
    let connection: WebSocketConnectionModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        WebSocketBadge(status: connection.status)
                        Text(connection.status.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(NooberTheme.wsStatusColor(connection.status))
                        Spacer()
                        Text("\(connection.frames.count) frames")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Text(connection.url)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary.opacity(0.8))
                        .textSelection(.enabled)
                }
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)

                // Frames list
                if connection.frames.isEmpty {
                    Text("No frames captured yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 1) {
                        ForEach(connection.frames.reversed()) { frame in
                            wsFrameRow(frame)
                        }
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(16)
        }
        .navigationTitle(connection.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func wsFrameRow(_ frame: WebSocketFrameModel) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Direction indicator
            Image(systemName: frame.direction == .sent ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(frame.direction == .sent ? NooberTheme.warning : NooberTheme.info)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(frame.frameType.rawValue)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(frame.isJSON ? NooberTheme.success : .secondary)
                    if frame.isJSON {
                        Text("JSON")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(NooberTheme.success)
                    }
                    Spacer()
                    Text(frame.sizeText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }

                Text(frame.payloadPreview)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.primary.opacity(0.8))
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }
}
