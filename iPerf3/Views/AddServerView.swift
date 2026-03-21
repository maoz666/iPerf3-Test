import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var port: String = "5201"

    @State private var mode: Int = 0
    @State private var streams: Int = 1
    @State private var duration: Int = 0

    var onAdd: (IperfServer) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server Information")) {

                    VStack(alignment: .leading) {
                        Text("Server Name")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("Optional", text: $name)
                    }

                    VStack(alignment: .leading) {
                        Text("Server Address")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        IPAddressField(address: $address)
                    }

                    VStack(alignment: .leading) {
                        Text("Port")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("5201", text: $port)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Test Settings")) {

                    VStack(alignment: .leading) {
                        Text("Transmit Mode")
                            .foregroundColor(.gray)

                        Picker("", selection: $mode) {
                            Text("Download").tag(0)
                            Text("Upload").tag(1)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading) {
                        Text("Streams")
                            .foregroundColor(.gray)

                        Picker("", selection: $streams) {
                            ForEach(1...5, id: \.self) { Text("\($0)") }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading) {
                        Text("Duration")
                            .foregroundColor(.gray)

                        Picker("", selection: $duration) {
                            Text("10s").tag(0)
                            Text("30s").tag(1)
                            Text("5min").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .navigationTitle("Add Server")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let server = IperfServer(
                            name: name.isEmpty ? address : name,
                            address: address,
                            port: Int(port) ?? 5201,
                            mode: mode,
                            streams: streams,
                            duration: duration
                        )
                        onAdd(server)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - IP formatter

    func formatIP(_ input: String) -> String {
        let numbers = input.filter { "0123456789".contains($0) }
        var result = ""

        for (index, char) in numbers.enumerated() {
            if index != 0 && index % 3 == 0 && result.filter({ $0 == "." }).count < 3 {
                result.append(".")
            }
            result.append(char)
        }

        return result
    }
}
