//
//  AddServerView.swift
//  iPerf3
//
//  Created by Artem Peshkov on 18/03/2026.
//


import SwiftUI

struct AddServerView: View {
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var ipOctets: [String] = ["", "", "", ""]
    @State private var port: String = "5201"
    @State private var mode: Int = 0
    @State private var streams: Int = 1
    @State private var duration: Int = 0

    var onAdd: (IperfServer) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server Information")) {
                    TextField("Server name (optional)", text: $name)
                    HStack {
                        ForEach(0..<4, id: \.self) { i in
                            TextField("0", text: $ipOctets[i])
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .onChange(of: ipOctets[i]) { oldValue, newValue in
                                    ipOctets[i] = validateOctet(newValue)
                                }
                            if i < 3 { Text(".") }
                        }
                    }
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Test Settings")) {
                    Picker("Transmit Mode", selection: $mode) {
                        Text("Download").tag(0)
                        Text("Upload").tag(1)
                    }
                    .pickerStyle(.segmented)

                    Picker("Streams", selection: $streams) {
                        ForEach(1...5, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)

                    Picker("Duration", selection: $duration) {
                        Text("10s").tag(0)
                        Text("30s").tag(1)
                        Text("5min").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Server")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let server = IperfServer(
                            name: name.isEmpty ? ipOctets.joined(separator: ".") : name,
                            address: ipOctets.joined(separator: "."),
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

    func validateOctet(_ input: String) -> String {
        let digits = input.filter { "0123456789".contains($0) }
        if let val = Int(digits), val > 255 { return "255" }
        return digits
    }
}
