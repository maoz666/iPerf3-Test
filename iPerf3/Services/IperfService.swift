//
//  IperfService.swift
//  iPerf3
//
//  Created by Artem Peshkov on 19/03/2026.
//

import Foundation
import IperfSwift
import Combine

class IperfService: ObservableObject {

    @Published var currentSpeed: Double = 0
    @Published var history: [Double] = []
    @Published var isRunning = false
    @Published var state: IperfRunnerState = .unknown

    private var runner: IperfRunner?

    func start(server: IperfServer) {
        history.removeAll()
        isRunning = true

        var config = IperfConfiguration()
        config.address = server.address
        config.port = server.port
        config.numStreams = server.streams
        config.role = .client
        config.prot = .tcp
        config.reverse = server.mode == 0 ? .download : .upload
        config.duration = durationValue(server.duration)
        config.reporterInterval = 1

        runner = IperfRunner(with: config)

        runner?.start(
            { [weak self] interval in
                self?.handleInterval(interval)
            },
            { [weak self] error in
                self?.handleError(error)
            },
            { [weak self] state in
                self?.handleState(state)
            }
        )
    }

    func stop() {
        runner?.stop()
        isRunning = false
    }

    private func handleInterval(_ interval: IperfIntervalResult) {
        let mbps = interval.throughput.Mbps
        DispatchQueue.main.async {
            self.currentSpeed = mbps
            self.history.append(mbps)
        }
    }

    private func handleError(_ error: IperfError) {
        DispatchQueue.main.async {
            self.isRunning = false
            print("iperf error:", error.debugDescription)
        }
    }

    private func handleState(_ state: IperfRunnerState) {
        DispatchQueue.main.async {
            self.state = state
            if state == .finished || state == .error {
                self.isRunning = false
            }
        }
    }

    private func durationValue(_ d: Int) -> TimeInterval {
        switch d {
        case 0: return 10
        case 1: return 30
        default: return 300
        }
    }

    var stateText: String {
        switch state {
        case .running: return "Running"
        case .ready: return "Ready"
        case .initialising: return "Connecting..."
        case .finished: return "Completed"
        case .error: return "Error"
        default: return "Idle"
        }
    }
}
