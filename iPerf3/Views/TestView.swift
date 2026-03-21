import SwiftUI
import Charts

struct SpeedPoint: Identifiable {
    let id = UUID()
    let time: Double
    let value: Double
}

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

                Text("Server Information")
                    .font(.headline)

                VStack(alignment: .leading) {
                    Text("Server Name").foregroundColor(.gray)
                    Text(server.name ?? "-")
                }

                VStack(alignment: .leading) {
                    Text("Server Address").foregroundColor(.gray)
                    Text(server.address)
                }

                VStack(alignment: .leading) {
                    Text("Port").foregroundColor(.gray)

                    TextField("", text: $port)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading) {
                    Text("Transmit Mode").foregroundColor(.gray)

                    Picker("", selection: $server.mode) {
                        Text("Download").tag(0)
                        Text("Upload").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Streams").foregroundColor(.gray)

                    Picker("", selection: $server.streams) {
                        ForEach(1...5, id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading) {
                    Text("Duration").foregroundColor(.gray)

                    Picker("", selection: $server.duration) {
                        Text("10s").tag(0)
                        Text("30s").tag(1)
                        Text("5min").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                Text(formatSpeed(iperf.currentSpeed))
                    .font(.system(size: 42, weight: .bold))
                    .frame(maxWidth: .infinity)

                Chart(speedPoints) { point in

                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Speed", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(.init(lineWidth: 3))
                    .foregroundStyle(.blue)

                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("Speed", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.35), .blue.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 220)
                .chartXAxis {

                    AxisMarks(values: .stride(by: 5)) { value in

                        AxisGridLine()
                        AxisTick()

                        if let sec = value.as(Double.self) {
                            AxisValueLabel(formatTime(sec))
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .transaction { t in
                    t.animation = nil   // ⭐ УБИВАЕМ МИГАНИЕ
                }

                HStack {
                    stat("Min", iperf.history.min() ?? 0)
                    stat("Avg", avg())
                    stat("Max", iperf.history.max() ?? 0)
                }

                Text(iperf.stateText)
                    .foregroundColor(.gray)

                Button {

                    syncServer()

                    if iperf.isRunning {
                        iperf.stop()
                    } else {
                        iperf.start(server: server)
                    }

                } label: {

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

    var speedPoints: [SpeedPoint] {
        iperf.history.enumerated().map {
            SpeedPoint(
                time: Double($0.offset),
                value: $0.element
            )
        }
    }

    func formatTime(_ sec: Double) -> String {
        let total = Int(sec)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
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
