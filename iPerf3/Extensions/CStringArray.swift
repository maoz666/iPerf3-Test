//
//  CStringArray.swift
//  iPerf3
//
//  Created by Artem Peshkov on 19/03/2026.
//

import Foundation

extension Array where Element == String {
    func withCStringArray<Result>(_ body: ([UnsafeMutablePointer<CChar>?]) -> Result) -> Result {
        let cStrings = self.map { strdup($0) }
        let result = body(cStrings + [nil])
        for ptr in cStrings {
            free(ptr)
        }
        return result
    }
}
