import SwiftUI

struct UserDefaultsEditView: View {

    @ObservedObject var store: UserDefaultsStore
    let existingEntry: UserDefaultsEntry?
    @Environment(\.presentationMode) private var presentationMode

    @State private var key: String = ""
    @State private var value: String = ""

    private var isEditing: Bool { existingEntry != nil }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Key name", text: $key)
                        .font(.system(size: 14, design: .monospaced))
                        .autocapitalization(.none)
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
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        NooberTextEditor(text: $value)
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
            .nooberNavigationBarTitle(isEditing ? "Edit Value" : "Add Entry")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                    .foregroundColor(.secondary),
                trailing: Button("Save") {
                    store.setValue(value, forKey: key)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NooberTheme.accent)
                .disabled(key.trimmingCharacters(in: .whitespaces).isEmpty)
            )
            .onAppear {
                if let entry = existingEntry {
                    key = entry.key
                    value = store.editableValue(forKey: entry.key)
                }
            }
        }
    }
}
