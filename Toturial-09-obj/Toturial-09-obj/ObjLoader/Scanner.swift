//
//  Scanner.swift
//  ObjTest
//
//  Created by mkil on 2019/6/12.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation

enum ScannerErrors: Error {
    case unreadableData(error: String)
    case invalidData(error: String)
}

class Scanner {
    
    var isAtEnd: Bool {
        get {
            return scanner.isAtEnd
        }
    }
    
    fileprivate let scanner: Foundation.Scanner
    fileprivate let source: String
    
    init(source: String) {
        scanner = Foundation.Scanner(string: source)
        self.source = source
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
    }
    
    func moveToNextLine() {
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: nil)
        scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
    }
    
    func readMarker() -> NSString? {
        var marker: NSString?
        scanner.scanUpToCharacters(from: CharacterSet.whitespaces, into: &marker)
        
        return marker
    }
    
    func readLine() -> NSString? {
        var string: NSString?
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &string)
        return string
    }
    
    func readInt() throws -> Int32 {
        var value = Int32.max
        if scanner.scanInt32(&value) {
            return value
        }
        
        throw ScannerErrors.invalidData(error: "Invalid Int value")
    }
    
    func readDouble() throws -> Double {
        var value = Double.infinity
        if scanner.scanDouble(&value) {
            return value
        }
        
        throw ScannerErrors.invalidData(error: "Invalid Double value")
    }
    
    func readString() throws -> NSString {
        var string: NSString?
        
        scanner.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &string)
        
        if let string = string {
            return string
        }
        
        throw ScannerErrors.invalidData(error: "Invalid String value")
    }
    
    func readTokens() throws -> [NSString] {
        var string: NSString?
        var result: [NSString] = []
        
        while scanner.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &string) {
            result.append(string!)
        }
        
        return result
    }
    
    func reset() {
        scanner.scanLocation = 0
    }
    
}

final class ObjScanner: Scanner {
    
    // 读取一行的顶点数据
    func readVertex() throws -> [Double]? {
        var x = Double.infinity
        var y = Double.infinity
        var z = Double.infinity
        
        guard scanner.scanDouble(&x) else {
            throw ScannerErrors.unreadableData(error: "Bad vertex definition missing x component")
        }
        
        guard scanner.scanDouble(&y) else {
            throw ScannerErrors.unreadableData(error: "Bad vertex definition missing y component")
        }
        
        guard scanner.scanDouble(&z) else {
            throw ScannerErrors.unreadableData(error: "Bad vertex definition missing z component")
        }
        
        return [x,y,z]
    }
    
    // 读取一行纹理数据
    func readTextureCoord() throws -> [Double]? {
        var u = Double.infinity
        var v = Double.infinity
        
        guard scanner.scanDouble(&u) else {
            throw ScannerErrors.unreadableData(error: "Bad texture definition missing u component")
        }
        
        guard scanner.scanDouble(&v) else {
            throw ScannerErrors.unreadableData(error: "Bad texture definition missing v component")
        }
        
        return [u,v]
    }
    
    // 读取一行Face索引数据
    func readFace() throws -> [Int]? {
        var result: [Int] = []
        while true {
            var v, vn, vt: Int?
            var tmp: Int32 = -1
            
            guard scanner.scanInt32(&tmp) else {
                break
            }
            
            v = Int(tmp)
            
            guard scanner.scanString("/", into: nil) else {
                throw ObjLoadingError.unexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }
            
            if scanner.scanInt32(&tmp) {
                vt = Int(tmp)
            }
            guard scanner.scanString("/", into: nil) else {
                throw ObjLoadingError.unexpectedFileFormat(error: "Lack of '/' when parsing face definition, each vertex index should contain 2 '/'")
            }
            
            if scanner.scanInt32(&tmp) {
                vn = Int(tmp)
            }
            
            result.append(contentsOf: [v!,vt!,vn!])
        }
        
        return result
    }
    
    
}
