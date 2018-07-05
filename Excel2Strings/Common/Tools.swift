//
//  Tools.swift
//  Excel2Strings
//
//  Created by Isaac on 2018/7/4.
//  Copyright © 2018年 IsaacPan. All rights reserved.
//

import Foundation

typealias Handle = () -> ()

func performOnMain(handle: @escaping Handle) {
    DispatchQueue.main.async {
        handle()
    }
}

func performOnGlobal(handle: @escaping Handle) {
    DispatchQueue.global().async {
        handle()
    }
}

public extension String {
    public func ABCtoNumber() -> Int? {
        let character = self.uppercased()
        var finalValue: Int?
        if character.count != 1 {
            return nil
        }
        if let value = character.unicodeScalars.first?.value {
            finalValue = Int(value) - 64
        }
        if let value = finalValue {
            if value > 26 {
                return nil
            }
        }
        return finalValue
    }
}

public extension Int {
    public func numberToABC() -> String? {
        switch self {
        case 1 ..< 27:
            if let value = Unicode.Scalar(self+64) {
                return String(value)
            }
        default:
            return nil
        }
        return nil
    }
}
