import SwiftUI
import UIKit

struct NetworkDetailView: View {

    let request: NetworkRequestModel
    @State private var selectedTab = 0
    @State private var copiedField: String?
    @State private var searchText = ""
    @State private var bodyViewMode: BodyViewMode = .list
    @State private var showReplaySheet = false
    @State private var showCreateMockSheet = false
    @State private var showCreateInterceptSheet = false
    @State private var isBodyExpanded = false

    private enum BodyViewMode: String, CaseIterable {
        case list = "List"
        case raw = "Raw"
    }

    private var curlCommand: String {
        CURLGenerator.generate(from: request)
    }

    // Pre-computed flattened bodies
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
            // Search bar
            NooberSearchBar(text: $searchText, placeholder: "Search headers, body, values...")
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Summary header card
            if searchText.isEmpty {
                headerCard
            }

            // Tab picker
            Picker("Section", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Request").tag(1)
                Text("Response").tag(2)
                Text("cURL").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .onChange(of: selectedTab) { _ in NooberTheme.hapticLight() }

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case 0: overviewTab
                case 1: requestTab
                case 2: responseTab
                case 3: curlTab
                default: EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)
        }
        .navigationTitle(request.path)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showReplaySheet = true } label: { Label("Replay", systemImage: "arrow.clockwise") }
                    Button { RequestReplayer.replay(from: request) } label: { Label("Quick Replay", systemImage: "paperplane") }
                    Divider()
                    Button { showCreateMockSheet = true } label: { Label("Create Mock Rule", systemImage: "wand.and.rays") }
                    Button { showCreateInterceptSheet = true } label: { Label("Create Intercept Rule", systemImage: "hand.raised") }
                    Divider()
                    Button { copyFullDetails() } label: { Label("Copy Details", systemImage: "doc.on.doc") }
                    Button { copyCurl() } label: { Label("Copy cURL", systemImage: "terminal") }
                    Button { shareRequest() } label: { Label("Share", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(NooberTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showReplaySheet) {
            ReplayEditView(request: request)
        }
        .sheet(isPresented: $showCreateMockSheet) {
            MockRuleEditView(store: RulesStore.shared, prefillFromRequest: request)
        }
        .sheet(isPresented: $showCreateInterceptSheet) {
            InterceptRuleEditView(store: RulesStore.shared, prefillFromRequest: request)
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Badges row
            HStack(spacing: 6) {
                MethodBadge(method: request.method)
                StatusBadge(statusCode: request.statusCode, category: request.statusCodeCategory)
                ContentTypeBadge(contentType: request.contentType)
                Spacer()
                DurationLabel(duration: request.duration)
                Text(request.responseSizeText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // URL
            Text(request.url)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(2)
                .textSelection(.enabled)

            // Mock / Rewrite indicators
            if request.isMocked {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.rays").font(.system(size: 11))
                    Text("Mocked response").font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(NooberTheme.mock)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NooberTheme.mock.opacity(0.1)))
            }
            if request.isIntercepted {
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised").font(.system(size: 11))
                    Text("Intercepted request").font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.15))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(red: 0.95, green: 0.55, blue: 0.15).opacity(0.1)))
            }
            if request.isEnvironmentRewritten {
                HStack(spacing: 4) {
                    Image(systemName: "server.rack").font(.system(size: 11))
                    Text("Environment rewritten").font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(NooberTheme.success)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NooberTheme.success.opacity(0.1)))
            }
            if let originalURL = request.originalURL {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.swap").font(.system(size: 11))
                    Text("Rewritten from: \(originalURL)").font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(NooberTheme.rewrite)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NooberTheme.rewrite.opacity(0.1)))
            }

            // Error
            if let error = request.errorDescription {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 11))
                    Text(error).font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(NooberTheme.error)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(NooberTheme.error.opacity(0.1)))
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                detailSection("General") {
                    filteredRows([
                        ("Method", request.method),
                        ("Host", request.host),
                        ("Path", request.path),
                        ("Status", request.statusCode.map(String.init) ?? "—"),
                        ("URL", request.url),
                    ])
                }

                detailSection("Timing & Size") {
                    filteredRows([
                        ("Duration", request.durationText),
                        ("Response Size", request.responseSizeText),
                        ("MIME Type", request.mimeType ?? "—"),
                        ("Content Type", request.contentType.rawValue),
                    ])
                }

                if let queryItems = queryParams, !queryItems.isEmpty {
                    let filtered = filterKVPairs(queryItems)
                    if !filtered.isEmpty || searchText.isEmpty {
                        detailSection("Query Parameters") {
                            if filtered.isEmpty && !searchText.isEmpty {
                                noResultsLabel
                            } else {
                                ForEach(filtered.isEmpty ? queryItems : filtered, id: \.0) { key, value in
                                    detailRow(key, value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Request Tab

    private var requestTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Request Headers
                let headers = filteredHeaders(request.requestHeaders)
                detailSection("Request Headers (\(request.requestHeaders.count))") {
                    if request.requestHeaders.isEmpty {
                        emptyLabel("No request headers")
                    } else if headers.isEmpty && !searchText.isEmpty {
                        noResultsLabel
                    } else {
                        ForEach(headers.isEmpty && searchText.isEmpty
                                ? request.requestHeaders.sorted(by: { $0.key < $1.key })
                                : headers, id: \.key) { key, value in
                            detailRow(key, value)
                        }
                    }
                }

                // Request Body
                detailSection("Request Body") {
                    if let body = request.requestBody, !body.isEmpty {
                        bodyContent(
                            data: body,
                            prettyText: request.prettyRequestBody,
                            kvItems: requestBodyKV
                        )
                    } else {
                        emptyLabel("No request body")
                    }
                }
            }
        }
    }

    // MARK: - Response Tab

    private var responseTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image preview
                if request.isImage, let img = request.responseImage, searchText.isEmpty {
                    detailSection("Image Preview") {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                            )
                            .padding(.vertical, 4)

                        detailRow("Dimensions", "\(Int(img.size.width)) × \(Int(img.size.height))")
                    }
                }

                // Response Headers
                let headers = filteredHeaders(request.responseHeaders)
                detailSection("Response Headers (\(request.responseHeaders.count))") {
                    if request.responseHeaders.isEmpty {
                        emptyLabel("No response headers")
                    } else if headers.isEmpty && !searchText.isEmpty {
                        noResultsLabel
                    } else {
                        ForEach(headers.isEmpty && searchText.isEmpty
                                ? request.responseHeaders.sorted(by: { $0.key < $1.key })
                                : headers, id: \.key) { key, value in
                            detailRow(key, value)
                        }
                    }
                }

                // Response Body
                detailSection("Response Body") {
                    if let body = request.responseBody, !body.isEmpty {
                        if request.isImage {
                            emptyLabel("Image data — \(request.responseSizeText)")
                        } else {
                            bodyContent(
                                data: body,
                                prettyText: request.prettyResponseBody,
                                kvItems: responseBodyKV
                            )
                        }
                    } else {
                        emptyLabel("No response body")
                    }
                }
            }
        }
    }

    // MARK: - cURL Tab

    private var curlTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Generated cURL command")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = curlCommand
                    flashCopied("cURL")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedField == "cURL" ? "checkmark" : "doc.on.doc")
                        Text(copiedField == "cURL" ? "Copied" : "Copy")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(copiedField == "cURL" ? NooberTheme.success : NooberTheme.accent)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill((copiedField == "cURL" ? NooberTheme.success : NooberTheme.accent).opacity(0.12)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if searchText.isEmpty {
                ScrollView([.horizontal, .vertical]) {
                    Text(curlCommand)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(NooberTheme.success)
                        .textSelection(.enabled)
                        .padding(16)
                }
            } else {
                // Highlight matching lines in cURL
                let lines = curlCommand.components(separatedBy: "\n")
                let matched = lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
                if matched.isEmpty {
                    noResultsView
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(matched.enumerated()), id: \.offset) { _, line in
                                highlightedText(line, query: searchText)
                                    .font(.system(size: 12, design: .monospaced))
                            }
                        }
                        .padding(16)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Body Content (List + Raw modes)

    private func bodyContent(data: Data, prettyText: String, kvItems: [JSONFlattener.KeyValue]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top bar: view mode picker + copy button
            HStack(spacing: 8) {
                // Only show List/Raw picker if we have KV items (i.e., it's valid JSON)
                if !kvItems.isEmpty {
                    Picker("View", selection: $bodyViewMode) {
                        ForEach(BodyViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = prettyText
                    flashCopied("body")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copiedField == "body" ? "checkmark" : "doc.on.doc")
                        Text(copiedField == "body" ? "Copied" : "Copy")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(copiedField == "body" ? NooberTheme.success : NooberTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill((copiedField == "body" ? NooberTheme.success : NooberTheme.accent).opacity(0.12)))
                }
            }

            // Content based on view mode
            if bodyViewMode == .list && !kvItems.isEmpty {
                keyValueListView(items: kvItems)
            } else {
                rawBodyView(prettyText: prettyText)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Key-Value List View

    private func keyValueListView(items: [JSONFlattener.KeyValue]) -> some View {
        let filtered: [JSONFlattener.KeyValue]
        if searchText.isEmpty {
            filtered = items
        } else {
            filtered = items.filter {
                $0.key.localizedCaseInsensitiveContains(searchText) ||
                $0.value.localizedCaseInsensitiveContains(searchText)
            }
        }

        return VStack(alignment: .leading, spacing: 0) {
            if filtered.isEmpty && !searchText.isEmpty {
                noResultsLabel
            } else {
                // Show count
                Text("\(filtered.count) field\(filtered.count == 1 ? "" : "s")")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 6)

                ForEach(filtered) { item in
                    kvRow(item: item)
                }
            }
        }
    }

    private func kvRow(item: JSONFlattener.KeyValue) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            // Key with indentation based on depth
            HStack(spacing: 0) {
                if item.depth > 0 {
                    // Visual indentation
                    ForEach(0..<item.depth, id: \.self) { _ in
                        Rectangle()
                            .fill(NooberTheme.accent.opacity(0.15))
                            .frame(width: 1.5)
                            .padding(.trailing, 8)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    if !searchText.isEmpty {
                        highlightedText(item.key, query: searchText)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    } else {
                        Text(item.key)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(item.isLeaf ? .secondary : NooberTheme.accent)
                    }

                    if item.isLeaf {
                        if !searchText.isEmpty {
                            highlightedText(item.value, query: searchText)
                                .font(.system(size: 12, design: .monospaced))
                        } else {
                            Text(item.value)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(valueColor(item.value))
                        }
                    } else {
                        Text(item.value)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(uiColor: .tertiaryLabel))
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            let copyText = item.isLeaf ? "\(item.key): \(item.value)" : item.key
            UIPasteboard.general.string = copyText
            flashCopied(item.id)
        }
        .background(
            copiedField == item.id
                ? NooberTheme.success.opacity(0.08)
                : Color.clear
        )
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, CGFloat(item.depth) * 10)
        }
    }

    // MARK: - Raw Body View

    private func rawBodyView(prettyText: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if !searchText.isEmpty {
                    let lines = prettyText.components(separatedBy: "\n")
                    let matched = lines.filter { $0.localizedCaseInsensitiveContains(searchText) }
                    if matched.isEmpty {
                        noResultsLabel
                    } else {
                        ScrollView(.horizontal, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 1) {
                                ForEach(Array(matched.enumerated()), id: \.offset) { _, line in
                                    highlightedText(line, query: searchText)
                                        .font(.system(size: 11, design: .monospaced))
                                }
                            }
                        }
                        .frame(maxHeight: isBodyExpanded ? .infinity : 400)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(prettyText)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary.opacity(0.9))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: isBodyExpanded ? .infinity : 400)
                }
            }

            // Show expand/collapse only when content is large enough to be clipped
            if prettyText.components(separatedBy: "\n").count > 15 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isBodyExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isBodyExpanded ? "chevron.up" : "chevron.down")
                        Text(isBodyExpanded ? "Collapse" : "Expand Full JSON")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NooberTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(NooberTheme.accent.opacity(0.08))
                    .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - Search Helpers

    private func filteredRows(_ pairs: [(String, String)]) -> some View {
        let filtered = searchText.isEmpty ? pairs : filterKVPairs(pairs)
        return Group {
            if filtered.isEmpty && !searchText.isEmpty {
                noResultsLabel
            } else {
                ForEach(searchText.isEmpty ? pairs : filtered, id: \.0) { key, value in
                    if !searchText.isEmpty {
                        highlightedDetailRow(key, value)
                    } else {
                        detailRow(key, value)
                    }
                }
            }
        }
    }

    private func filteredHeaders(_ headers: [String: String]) -> [(key: String, value: String)] {
        guard !searchText.isEmpty else { return [] }
        return headers.sorted(by: { $0.key < $1.key }).filter {
            $0.key.localizedCaseInsensitiveContains(searchText) ||
            $0.value.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func filterKVPairs(_ pairs: [(String, String)]) -> [(String, String)] {
        pairs.filter {
            $0.0.localizedCaseInsensitiveContains(searchText) ||
            $0.1.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Highlighted Text

    private func highlightedText(_ text: String, query: String) -> some View {
        let ranges = highlightRanges(in: text, query: query)
        if ranges.isEmpty {
            return Text(text).foregroundColor(.primary.opacity(0.9))
        }

        var result = Text("")
        var currentIndex = text.startIndex

        for range in ranges {
            // Text before match
            if currentIndex < range.lowerBound {
                let before = String(text[currentIndex..<range.lowerBound])
                result = result + Text(before).foregroundColor(.primary.opacity(0.7))
            }
            // Matched text
            let matched = String(text[range])
            result = result + Text(matched)
                .foregroundColor(NooberTheme.accent)
                .fontWeight(.bold)

            currentIndex = range.upperBound
        }

        // Remaining text
        if currentIndex < text.endIndex {
            let remaining = String(text[currentIndex...])
            result = result + Text(remaining).foregroundColor(.primary.opacity(0.7))
        }

        return result
    }

    private func highlightRanges(in text: String, query: String) -> [Range<String.Index>] {
        guard !query.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: query, options: .caseInsensitive, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<text.endIndex
        }
        return ranges
    }

    private func highlightedDetailRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            highlightedText(key, query: searchText)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .frame(minWidth: 90, alignment: .trailing)

            highlightedText(value, query: searchText)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            UIPasteboard.general.string = value
            flashCopied(key)
        }
    }

    // MARK: - Value Coloring

    private func valueColor(_ value: String) -> Color {
        switch value.lowercased() {
        case "null":
            return Color(uiColor: .tertiaryLabel)
        case "true":
            return NooberTheme.success
        case "false":
            return NooberTheme.error
        default:
            if Double(value) != nil {
                return NooberTheme.info
            }
            return .primary
        }
    }

    // MARK: - Reusable Components

    private var noResultsLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 13))
        }
        .foregroundColor(Color(uiColor: .tertiaryLabel))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }

    private var noResultsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
            Text("No matches for \"\(searchText)\"")
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(Color(uiColor: .tertiaryLabel))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }

    private func detailSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(NooberTheme.accent)
                .textCase(.uppercase)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider().padding(.leading, 16)
        }
    }

    private func detailRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(key)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(minWidth: 90, alignment: .trailing)

            Text(value)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            UIPasteboard.general.string = value
            flashCopied(key)
        }
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundColor(Color(uiColor: .tertiaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    // MARK: - Query Params

    private var queryParams: [(String, String)]? {
        guard let url = URL(string: request.url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty else { return nil }
        return items.map { ($0.name, $0.value ?? "") }
    }

    // MARK: - Actions

    private func flashCopied(_ field: String) {
        NooberTheme.hapticSuccess()
        withAnimation(.spring(response: 0.3)) { copiedField = field }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { copiedField = nil }
        }
    }

    private func copyFullDetails() {
        let text = """
        \(request.method) \(request.url)
        Status: \(request.statusCode.map(String.init) ?? "—")
        Duration: \(request.durationText)
        Size: \(request.responseSizeText)
        MIME: \(request.mimeType ?? "—")

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
        flashCopied("details")
    }

    private func copyCurl() {
        UIPasteboard.general.string = curlCommand
        flashCopied("cURL")
    }

    private func shareRequest() {
        let text = """
        \(request.method) \(request.url)
        Status: \(request.statusCode.map(String.init) ?? "—")
        Duration: \(request.durationText)
        Size: \(request.responseSizeText)

        \(curlCommand)
        """
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        // Present from the topmost window (the debugger window) so the sheet
        // appears above Noober, not behind it.
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

// MARK: - cURL Generator

enum CURLGenerator {
    static func generate(from req: NetworkRequestModel) -> String {
        var parts = ["curl"]

        // Method
        if req.method != "GET" {
            parts.append("-X \(req.method)")
        }

        // Headers
        for (key, value) in req.requestHeaders.sorted(by: { $0.key < $1.key }) {
            let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
            parts.append("-H '\(key): \(escaped)'")
        }

        // Body
        if let body = req.requestBody, !body.isEmpty {
            if let bodyString = String(data: body, encoding: .utf8) {
                let escaped = bodyString.replacingOccurrences(of: "'", with: "'\\''")
                parts.append("-d '\(escaped)'")
            }
        }

        // URL
        let escapedURL = req.url.replacingOccurrences(of: "'", with: "'\\''")
        parts.append("'\(escapedURL)'")

        return parts.joined(separator: " \\\n  ")
    }
}
