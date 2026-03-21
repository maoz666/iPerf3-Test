//
//  iPerf3App.swift
//  iPerf3
//
//  Created by Artem Peshkov on 18/03/2026.
//

import SwiftUI

@main
struct Iperf3App: App {
    var body: some Scene {
        WindowGroup {
            ServerListView()
        }
    }
}
