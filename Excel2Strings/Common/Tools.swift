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
    fileprivate  func filtENAfter() -> String {
        var value = self.filter { (c) -> Bool in
            if let value = c.unicodeScalars.first?.value {
                switch value {
                case 65 ..< 91:
                    return true
                case 97 ..< 123:
                    return true
                default:
                    return false
                }
            }
            return false
        }
        value = value.lowercased()
        return value
    }
    
    fileprivate func filtChAfter() -> String {
        var value = self
        let unsafeSlices = ["\\n","\\t","\\r"]
        for slice in unsafeSlices {
            if value.contains(slice) {
                value = value.components(separatedBy: slice).reduce("", {$0 + $1})
            }
        }
        let ignoreC = [",","，","。",".","!","！","?","？","、","\n","\t","\r","\\"," "]
        value = value.filter { (c) -> Bool in
            if ignoreC.contains("\(c)") {
                return false
            }
            return true
        }
        value = value.lowercased()
        return value
    }
    public func blurryEnMatch(with content: String) -> Bool {
        if self.filtENAfter() == content.filtENAfter() {
            return true
        } else {
            return false
        }
    }
    public func blurryCHMatch(with content: String) -> Bool {
        if self.filtChAfter() == content.filtChAfter() {
            return true
        }
        return false
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
