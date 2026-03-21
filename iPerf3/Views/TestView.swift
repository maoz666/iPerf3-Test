//
//  TestView.swift
//  iPerf3
//
//  Created by Artem Peshkov on 18/03/2026.
//


import SwiftUI

struct TestView: View {
    @State var server: IperfServer
    @StateObject private var iperf = IperfService()

    @State private var ipOctets: [String] = ["", "", "", ""]
    @State private var port: String = "5201"

    init(server: IperfServer) {
        _server = State(initialValue: server)
        let parts = server.address.split(separator: ".").map { String($0) }
        _ipOctets = State(initialValue: parts + Array(repeating: "", count: max(0, 4 - parts.count)))
        _port = State(initialValue: "\(server.port)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Server Info (editable in test)
                Section(header: Text("Server Information")) {
                    TextField("Optional name", text: $server.name.bound)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        ForEach(0..<4, id: \.self) { i in
                            TextField("0", text: $ipOctets[i])
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: ipOctets[i]) { oldValue, newValue in
                                    ipOctets[i] = validateOctet(newValue)
                                }
                            if i < 3 { Text(".") }
                        }
                    }

                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: port) { oldValue, newValue in
                            port = String(newValue.filter { "0123456789".contains($0) })
                        }
                }

                // Test Settings
                Section(header: Text("Test Settings")) {
                    Picker("Transmit Mode", selection: $server.mode) {
                        Text("Download").tag(0)
                        Text("Upload").tag(1)
                    }.pickerStyle(.segmented)

                    Picker("Streams", selection: $server.streams) {
                        ForEach(1...5, id: \.self) { Text("\($0)") }
                    }.pickerStyle(.segmented)

                    Picker("Duration", selection: $server.duration) {
                        Text("10s").tag(0)
                        Text("30s").tag(1)
                        Text("5min").tag(2)
                    }.pickerStyle(.segmented)
                }

                Divider()

                // Speed
                Text(formatSpeed(iperf.currentSpeed))
                    .font(.system(size: 42, weight: .bold))
                    .frame(maxWidth: .infinity)

                // Graph
                GeometryReader { geo in
                    Path { path in
                        let data = iperf.history
                        guard data.count > 1 else { return }
                        let step = geo.size.width / CGFloat(data.count - 1)
                        for i in data.indices {
                            let x = CGFloat(i) * step
                            let y = geo.size.height * (1 - CGFloat(data[i] / (data.max() ?? 1)))
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(.blue, lineWidth: 2)
                }
                .frame(height: 160)

                // Stats
                HStack {
                    stat("Min", iperf.history.min() ?? 0)
                    stat("Avg", avg())
                    stat("Max", iperf.history.max() ?? 0)
                }

                // Status
                Button(action: {
                    syncServer()
                    if iperf.isRunning {
                        iperf.stop()
                    } else {
                        iperf.start(server: server)
                    }
                }) {
                    Text(iperf.isRunning ? "Stop" : "Start Test")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(iperf.isRunning ? .red : .blue) // красная при Stop, синяя при Start
                .padding(.vertical, 20)
            }
            .padding()
        }
        .navigationTitle(server.name ?? server.address)
    }

    func syncServer() {
        server.address = ipOctets.joined(separator: ".")
        server.port = Int(port) ?? 5201
    }

    func stat(_ t: String, _ v: Double) -> some View {
        VStack {
            Text(t)
            Text(formatSpeed(v))
        }
        .frame(maxWidth: .infinity)
    }

    func avg() -> Double {
        let h = iperf.history
        return h.isEmpty ? 0 : h.reduce(0,+)/Double(h.count)
    }

    func formatSpeed(_ v: Double) -> String {
        if v > 1000 { return String(format: "%.2f Gbps", v/1000) }
        else if v > 1 { return String(format: "%.2f Mbps", v) }
        else { return String(format: "%.2f Kbps", v*1000) }
    }

    func validateOctet(_ input: String) -> String {
        let digits = input.filter { "0123456789".contains($0) }
        if let val = Int(digits), val > 255 { return "255" }
        return digits
    }
}
