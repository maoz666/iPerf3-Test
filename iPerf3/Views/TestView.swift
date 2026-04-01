//
//  SpeedPoint.swift
//  iPerf3
//
//  Created by Artem Peshkov on 01/04/2026.
//


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

    @State private var visibleEnd: Double = 20
    private let window: Double = 20

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
        .onChange(of: iperf.history.count) { _ in
            updateVisibleDomain()
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
        Text(formatSpeed(iperf.currentSpeed))
            .font(.system(size: 42, weight: .bold))
            .frame(maxWidth: .infinity)
    }

    var chartSection: some View {

        let start = max(0.0, visibleEnd - window)
        let range: ClosedRange<Double> = start...visibleEnd

        return Chart(speedPoints) { point in

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
            .foregroundStyle(.blue.opacity(0.15))
        }
        .chartXScale(domain: range)
        .frame(height: 220)

        // ❌ УБРАЛИ ОСЬ X
        .chartXAxis(.hidden)

        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .transaction { $0.animation = nil }
    }

    var statsSection: some View {
        HStack {
            stat("Min", iperf.history.min() ?? 0)
            stat("Avg", avg())
            stat("Max", iperf.history.max() ?? 0)
        }
    }

    var startButton: some View {

        Button {

            server.port = Int(port) ?? 5201

            if iperf.isRunning {
                iperf.stop()
                visibleEnd = window
            } else {
                visibleEnd = window
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

    var speedPoints: [SpeedPoint] {
        iperf.history.enumerated().map {
            SpeedPoint(
                time: Double($0.offset),
                value: $0.element
            )
        }
    }

    func updateVisibleDomain() {
        let newEnd = Double(iperf.history.count)

        withAnimation(.linear(duration: 1)) {
            visibleEnd = newEnd
        }
    }

    func avg() -> Double {
        let h = iperf.history
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
        if v > 1000 { return String(format: "%.2f Gbps", v/1000) }
        else if v > 1 { return String(format: "%.2f Mbps", v) }
        else { return String(format: "%.2f Kbps", v*1000) }
    }
}