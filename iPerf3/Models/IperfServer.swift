//
//  IperfServer.swift
//  iPerf3
//
//  Created by Artem Peshkov on 18/03/2026.
//


import Foundation

struct IperfServer: Identifiable, Codable {
    var id = UUID()
    var name: String?
    var address: String
    var port: Int
    var mode: Int // 0 = download, 1 = upload
    var streams: Int
    var duration: Int // 0 = 10s, 1 = 30s, 2 = 5min
}
