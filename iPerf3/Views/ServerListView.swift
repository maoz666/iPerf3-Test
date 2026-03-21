//
//  MainView.swift
//  iPerf3
//
//  Created by Artem Peshkov on 18/03/2026.
//


import SwiftUI

struct ServerListView: View {
    @State private var servers: [IperfServer] = []
    @State private var editMode: EditMode = .inactive
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(servers) { server in
                        NavigationLink(destination: TestView(server: server)) {
                            Text(server.name ?? server.address)
                        }
                    }
                    .onDelete { indexSet in
                        servers.remove(atOffsets: indexSet)
                    }
                    .onMove { indices, newOffset in
                        servers.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, $editMode)

                HStack {
                    Spacer()
                    Button("Servers") { /* future tab */ }
                    Spacer()
                    Button("History") { /* future tab */ }
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
                .clipShape(Capsule())
            }
            .navigationTitle("iPerf Servers")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddServerView { newServer in
                    servers.append(newServer)
                    showingAdd = false
                }
            }
        }
    }
}
