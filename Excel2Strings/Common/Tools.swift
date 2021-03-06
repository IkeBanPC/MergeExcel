//
//  Tools.swift
//  Excel2Strings
//
//  Created by Isaac on 2018/7/4.
//  Copyright © 2018年 IsaacPan. All rights reserved.
//

import Foundation


/// Define a common handle block.
typealias Handle = () -> ()


/// Execute Task On Main Thread.
///
/// - Parameter handle: Task to execute.
func performOnMain(handle: @escaping Handle) {
    DispatchQueue.main.async {
        handle()
    }
}


/// Execute Task On Global Thread.
///
/// - Parameter handle: Task to execute.
func performOnGlobal(handle: @escaping Handle) {
    DispatchQueue.global().async {
        handle()
    }
}


public extension String {
    
    /// ABC to 123
    ///
    /// - Returns: Int value
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
    
    /// Filt String and only latin letters left.
    ///
    /// - Returns: filtered string
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
    
    
    /// Filt Chinese String and remove symbols.
    ///
    /// - Returns: filtered string
    fileprivate func filtChAfter() -> String {
        var value = self
        // While some xlsx file content contains "\n" but XlsxReaderWriter regard it as "\\" plus "n", it's a rough solution for the confusing problem.
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
    
    
    /// Blurry match English Translations
    ///
    /// - Parameter content: content to match with
    /// - Returns: match result
    public func blurryEnMatch(with content: String) -> Bool {
        if self.filtENAfter() == content.filtENAfter() {
            return true
        } else {
            return false
        }
    }
    
    /// Blurry match Chinese Translations
    ///
    /// - Parameter content: content to match with
    /// - Returns: match result
    public func blurryCHMatch(with content: String) -> Bool {
        if self.filtChAfter() == content.filtChAfter() {
            return true
        }
        return false
    }
    
}

public extension Int {
    
    /// 123 To ABC
    ///
    /// - Returns: string value
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
