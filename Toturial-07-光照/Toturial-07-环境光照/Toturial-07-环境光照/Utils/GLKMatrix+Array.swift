//
//  GLKMatrix+Array.swift
//  Toturial-06-天空盒
//
//  Created by mkil on 2019/5/13.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import GLKit

extension GLKMatrix2 {
    var array: [Float] {
        return (0..<4).map { i in
            self[i]
        }
    }
}


extension GLKMatrix3 {
    var array: [Float] {
        return (0..<9).map { i in
            self[i]
        }
    }
}

extension GLKMatrix4 {
    var array: [Float] {
        return (0..<16).map { i in
            self[i]
        }
    }
}
