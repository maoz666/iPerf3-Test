import SwiftUI

struct IPAddressField: View {

    @Binding var address: String

    @State private var octets: [String] = ["", "", "", ""]
    @FocusState private var focusedIndex: Int?

    var body: some View {
        ZStack(alignment: .leading) {

            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    TextField("", text: $octets[index])
                        .keyboardType(.decimalPad)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .focused($focusedIndex, equals: index)
                        .onChange(of: octets[index]) { _, newValue in
                            handleInput(index: index, value: newValue)
                        }

                    if index < 3 {
                        Text(".")
                            .font(.body.weight(.semibold))
                    }
                }
            }
        }
        .onAppear {
            loadFromAddress()
        }
        .onChange(of: octets) { _, _ in
            updateAddress()
        }
    }

    // MARK: - Logic

    private func handleInput(index: Int, value: String) {
        // заменяем запятую
        let cleaned = value.replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789".contains($0) }

        var newValue = cleaned

        // ограничение 3 цифры
        if newValue.count > 3 {
            newValue = String(newValue.prefix(3))
        }

        // ограничение 255
        if let intVal = Int(newValue), intVal > 255 {
            newValue = "255"
        }

        octets[index] = newValue

        // авто переход вперед
        if newValue.count == 3 && index < 3 {
            focusedIndex = index + 1
        }

        // backspace назад
        if newValue.isEmpty && index > 0 {
            focusedIndex = index - 1
        }
    }

    private func updateAddress() {
        address = octets.joined(separator: ".")
    }

    private func loadFromAddress() {
        let parts = address.split(separator: ".").map { String($0) }
        for i in 0..<min(parts.count, 4) {
            octets[i] = parts[i]
        }
    }
}
