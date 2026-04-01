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

    // ring buffer
    @State private var displayData: [Double] = []

    // smoothing
    @State private var smoothedValue: Double = 0

    private let window: Int = 20
    private let maxY: Double = 1500

    init(server: IperfServer) {
        _server = State(initialValue: server)
        _port = State(initialValue: "\(server.port)")
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                serverSection

                Divider()

                speedLabel

                chartSection

                statsSection

                startButton
            }
            .padding()
        }
        .navigationTitle(server.name ?? server.address)
        .onChange(of: iperf.history.count) { _, _ in
            appendNewPoint()
        }
    }
}

// MARK: - Sections

private extension TestView {

    var serverSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Server Information")
                .font(.headline)

            VStack(alignment: .leading) {
                Text("Port").foregroundColor(.gray)
                TextField("", text: $port)
                    .textFieldStyle(.roundedBorder)
            }

            Picker("Mode", selection: $server.mode) {
                Text("Download").tag(0)
                Text("Upload").tag(1)
            }
            .pickerStyle(.segmented)

            Picker("Streams", selection: $server.streams) {
                ForEach(1...5, id: \.self) { Text("\($0)") }
            }
            .pickerStyle(.segmented)

            Picker("Duration", selection: $server.duration) {
                Text("10s").tag(0)
                Text("30s").tag(1)
                Text("5min").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

    var speedLabel: some View {
        Text(formatSpeed(smoothedValue))
            .font(.system(size: 42, weight: .bold))
            .frame(maxWidth: .infinity)
    }

    var chartSection: some View {

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
            .foregroundStyle(.blue.opacity(0.12))
        }
        .chartXScale(domain: 0...Double(window))

        // ✅ фиксированная Y
        .chartYScale(domain: 0...maxY)

        .frame(height: 220)
        .chartXAxis(.hidden)

        // тонкая сетка
        .chartYAxis {
            AxisMarks(
                position: .leading,
                values: Array(stride(from: 0, through: maxY, by: 300))
            ) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.gray.opacity(0.2))

                AxisTick()
                AxisValueLabel()
            }
        }

        .transaction { $0.animation = nil }
    }

    var statsSection: some View {
        HStack {
            stat("Min", displayData.min() ?? 0)
            stat("Avg", avg())
            stat("Max", displayData.max() ?? 0)
        }
    }

    var startButton: some View {

        Button {

            server.port = Int(port) ?? 5201

            if iperf.isRunning {
                iperf.stop()
                displayData.removeAll()
                smoothedValue = 0
            } else {
                displayData.removeAll()
                smoothedValue = 0
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
    }
}

// MARK: - Logic

private extension TestView {

    func appendNewPoint() {

        guard let raw = iperf.history.last else { return }

        // ⭐ adaptive smoothing
        let diff = abs(raw - smoothedValue)

        let alpha: Double
        if diff > 200 {
            alpha = 0.5   // быстрый отклик (пики)
        } else if diff > 50 {
            alpha = 0.3
        } else {
            alpha = 0.15  // плавность
        }

        smoothedValue = smoothedValue * (1 - alpha) + raw * alpha

        displayData.append(smoothedValue)

        if displayData.count > window {
            displayData.removeFirst()
        }
    }

    var speedPoints: [SpeedPoint] {
        displayData.enumerated().map {
            SpeedPoint(
                time: Double($0.offset),
                value: $0.element
            )
        }
    }

    func avg() -> Double {
        let h = displayData
        return h.isEmpty ? 0 : h.reduce(0,+)/Double(h.count)
    }

    func stat(_ t: String, _ v: Double) -> some View {
        VStack {
            Text(t)
            Text(formatSpeed(v))
        }
        .frame(maxWidth: .infinity)
    }

    func formatSpeed(_ v: Double) -> String {
        if v > 1000 { return String(format: "%.1f Gbps", v/1000) }
        else if v > 1 { return String(format: "%.1f Mbps", v) }
        else { return String(format: "%.1f Kbps", v*1000) }
    }
}
