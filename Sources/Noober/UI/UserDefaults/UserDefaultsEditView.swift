import SwiftUI

struct UserDefaultsEditView: View {

    @ObservedObject var store: UserDefaultsStore
    let existingEntry: UserDefaultsEntry?
    @Environment(\.dismiss) private var dismiss

    @State private var key: String = ""
    @State private var value: String = ""

    private var isEditing: Bool { existingEntry != nil }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Key name", text: $key)
                        .font(.system(size: 14, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .disabled(isEditing)
                        .opacity(isEditing ? 0.6 : 1)
                } header: {
                    Text("Key")
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if value.isEmpty {
                            Text("Enter value...")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(uiColor: .placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $value)
                            .font(.system(size: 14, design: .monospaced))
                            .frame(minHeight: 150)
                    }
                } header: {
                    Text("Value")
                }

                Section {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(NooberTheme.accent)
                        Text("Auto-detects type: Bool → Int → Double → JSON → String")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Value" : "Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        store.setValue(value, forKey: key)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NooberTheme.accent)
                    .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let entry = existingEntry {
                    key = entry.key
                    value = store.editableValue(forKey: entry.key)
                }
            }
        }
    }
}
