//
//  Binding+Optional.swift
//  iPerf3
//
//  Created by Artem Peshkov on 19/03/2026.
//

import SwiftUI

extension Binding where Value == String? {
    var bound: Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}
