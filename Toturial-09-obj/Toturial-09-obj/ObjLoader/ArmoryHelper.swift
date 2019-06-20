//
//  ArmoryHelper.swift
//  ObjTest
//
//  Created by mkil on 2019/6/12.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation

enum ArmoryLoadingErrors: Error {
    case NotFound
}

class ArmoryHelper {
    let bundle: Bundle
    
    var resourcePath: String {
        get {
            return bundle.resourcePath!
        }
    }
    
    init() {
        bundle = ArmoryHelper.loadBundle()
    }
    
    func loadObjArmory(_ name: String) throws -> String {
        guard let path = bundle.path(forResource: name, ofType: "obj") else {
            throw ArmoryLoadingErrors.NotFound
        }
        
        let string = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        
        return string
    }
    
    func loadMtlArmory(_ name: String) throws -> String {
        guard let path = bundle.path(forResource: name, ofType: "mtl") else {
            throw ArmoryLoadingErrors.NotFound
        }
        
        let string = try NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        return string as String
    }
    
    static private func loadBundle() -> Bundle {
        return Bundle(for: self)
    }
}
