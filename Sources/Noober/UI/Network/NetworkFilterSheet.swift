import SwiftUI

struct FilterSheetView: View {

    let methods: [String]
    let hosts: [String]

    @Binding var selectedMethods: Set<String>
    @Binding var selectedStatuses: Set<NetworkRequestModel.StatusCodeCategory>
    @Binding var selectedHosts: Set<String>

    @Environment(\.dismiss) private var dismiss

    private var totalActive: Int {
        selectedMethods.count + selectedStatuses.count + selectedHosts.count
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Methods
                    filterSection(title: "HTTP Method", icon: "arrow.up.arrow.down") {
                        chipGrid {
                            ForEach(methods, id: \.self) { method in
                                toggleChip(text: method, isSelected: selectedMethods.contains(method),
                                           color: NooberTheme.methodColor(method)) { toggleSet(&selectedMethods, value: method) }
                            }
                        }
                    }

                    // Status codes
                    filterSection(title: "Status Code", icon: "number") {
                        chipGrid {
                            ForEach(NetworkRequestModel.StatusCodeCategory.allCases, id: \.self) { cat in
                                toggleChip(text: cat.rawValue, isSelected: selectedStatuses.contains(cat),
                                           color: NooberTheme.statusColor(cat)) { toggleSet(&selectedStatuses, value: cat) }
                            }
                        }
                    }

                    // Hosts
                    if !hosts.isEmpty {
                        filterSection(title: "Host", icon: "server.rack") {
                            chipGrid {
                                ForEach(hosts, id: \.self) { host in
                                    toggleChip(text: host, isSelected: selectedHosts.contains(host),
                                               color: .secondary) { toggleSet(&selectedHosts, value: host) }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if totalActive > 0 {
                        Button("Reset") {
                            withAnimation(.spring(response: 0.25)) {
                                selectedMethods.removeAll(); selectedStatuses.removeAll(); selectedHosts.removeAll()
                            }
                        }
                        .foregroundColor(NooberTheme.error)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(NooberTheme.accent)
                }
            }
        }
    }

    private func chipGrid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], alignment: .leading, spacing: 8) { content() }
    }

    private func filterSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold)).foregroundColor(NooberTheme.accent)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.primary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(uiColor: .systemBackground)))
    }

    private func toggleChip(text: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.spring(response: 0.25)) { action() } } label: {
            HStack(spacing: 4) {
                if isSelected { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)) }
                Text(text).lineLimit(1)
            }
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? color : color.opacity(0.1)))
        }
    }

    private func toggleSet<T: Hashable>(_ set: inout Set<T>, value: T) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }
}
