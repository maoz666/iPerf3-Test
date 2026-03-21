import SwiftUI

struct TestView: View {
    @State var server: IperfServer
    @StateObject private var iperf = IperfService()

    @State private var port: String = "5201"

    init(server: IperfServer) {
        _server = State(initialValue: server)
        _port = State(initialValue: "\(server.port)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: - Server Info (READ ONLY)

                Text("Server Information")
                    .font(.headline)

                VStack(alignment: .leading) {
                    Text("Server Name")
                        .foregroundColor(.gray)
                    Text(server.name ?? "-")
                }

                VStack(alignment: .leading) {
                    Text("Server Address")
                        .foregroundColor(.gray)
                    Text(server.address)
                }

                VStack(alignment: .leading) {
                    Text("Port")
                        .foregroundColor(.gray)

                    TextField("", text: $port)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                // MARK: - Settings

                VStack(alignment: .leading) {
                    Text("Transmit Mode")
                        .foregroundColor(.gray)

                    Picker("", selection: $server.mode) {
                        Text("Download").tag(0)
                        Text("Upload").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Streams")
                        .foregroundColor(.gray)

                    Picker("", selection: $server.streams) {
                        ForEach(1...5, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Duration")
                        .foregroundColor(.gray)

                    Picker("", selection: $server.duration) {
                        Text("10s").tag(0)
                        Text("30s").tag(1)
                        Text("5min").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // MARK: - Speed

                Text(formatSpeed(iperf.currentSpeed))
                    .font(.system(size: 42, weight: .bold))
                    .frame(maxWidth: .infinity)

                // MARK: - Graph

                GeometryReader { geo in
                    Path { path in
                        let data = iperf.history
                        guard data.count > 1 else { return }

                        let step = geo.size.width / CGFloat(data.count - 1)

                        for i in data.indices {
                            let x = CGFloat(i) * step
                            let y = geo.size.height * (1 - CGFloat(data[i] / (data.max() ?? 1)))

                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(.blue, lineWidth: 2)
                }
                .frame(height: 160)

                // MARK: - Stats

                HStack {
                    stat("Min", iperf.history.min() ?? 0)
                    stat("Avg", avg())
                    stat("Max", iperf.history.max() ?? 0)
                }

                // MARK: - Status

                Text(iperf.stateText)
                    .foregroundColor(.gray)

                // MARK: - Button

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
                .tint(iperf.isRunning ? .red : .blue)
                .padding(.vertical, 20)
            }
            .padding()
        }
        .navigationTitle(server.name ?? server.address)
    }

    func syncServer() {
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
}
