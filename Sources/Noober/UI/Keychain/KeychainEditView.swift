import SwiftUI

struct KeychainEditView: View {

    @ObservedObject var store: KeychainStore
    let existingEntry: KeychainEntry?
    @Environment(\.dismiss) private var dismiss

    @State private var account: String = ""
    @State private var value: String = ""
    @State private var service: String = ""
    @State private var selectedClass: KeychainEntry.ItemClass = .genericPassword

    private var isEditing: Bool { existingEntry != nil }

    private var serviceLabel: String {
        selectedClass == .genericPassword ? "Service" : "Server"
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Class", selection: $selectedClass) {
                        ForEach(KeychainEntry.ItemClass.allCases, id: \.self) { cls in
                            Text(cls.rawValue).tag(cls)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isEditing)
                } header: {
                    Text("Item Class")
                }

                Section {
                    TextField("Account identifier", text: $account)
                        .font(.system(size: 14, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } header: {
                    Text("Account")
                }

                Section {
                    TextField(
                        selectedClass == .genericPassword ? "e.g. com.myapp" : "e.g. api.example.com",
                        text: $service
                    )
                    .font(.system(size: 14, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                } header: {
                    Text(serviceLabel)
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if value.isEmpty {
                            Text("Enter secret value...")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $value)
                            .font(.system(size: 14, design: .monospaced))
                            .frame(minHeight: 120)
                    }
                } header: {
                    Text("Value")
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.saveItem(
                            account: account,
                            value: value,
                            service: service,
                            itemClass: selectedClass,
                            originalEntry: existingEntry
                        )
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NooberTheme.accent)
                    .disabled(account.trimmingCharacters(in: .whitespaces).isEmpty ||
                              service.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    account = entry.account
                    service = entry.service
                    selectedClass = entry.itemClass
                    value = store.retrieveValue(for: entry) ?? ""
                }
            }
        }
    }
}
