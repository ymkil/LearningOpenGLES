//
//  Vector.swift
//  OpenGL-ES-05
//
//  Created by mkil on 2019/1/14.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation

public struct Vec3 {
    var x:Float
    var y:Float
    var z:Float
}

public struct Vec4 {
    var x:Float
    var y:Float
    var z:Float
    var w:Float
}

public struct Color {
    var r:Float
    var g:Float
    var b:Float
    var a:Float
}

public struct Vector {
    
    static func vectorCopy(out:UnsafeMutablePointer<Vec3>, into:UnsafePointer<Vec3>) {
        out[0].x = into[0].x
        out[0].y = into[0].y
        out[0].z = into[0].z
    }
    
    static func vectorAdd(out:UnsafeMutablePointer<Vec3>, a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) {
        out[0].x = a[0].x + b[0].x
        out[0].y = a[0].y + b[0].y
        out[0].z = a[0].z + b[0].z
    }
    
    static func vectorSubtract(out:UnsafeMutablePointer<Vec3>, a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) {
        out[0].x = a[0].x - b[0].x
        out[0].y = a[0].y - b[0].y
        out[0].z = a[0].z - b[0].z
    }
    
    static func crossProduct(out:UnsafeMutablePointer<Vec3>, a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) {
        out[0].x = a[0].y * b[0].z - a[0].z * b[0].y
        out[0].y = a[0].z * b[0].x - a[0].x * b[0].z
        out[0].z = a[0].x * b[0].y - b[0].y * a[0].x
    }
    
    static func dotProduct(a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) -> Float {
        return (a[0].x * b[0].x + a[0].y * b[0].y + a[0].z * b[0].z)
    }
    
    static func vectorLerp(out:UnsafeMutablePointer<Vec3>, a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>, t:Float) {
        out[0].x = (a[0].x * (1 - t) + b[0].x * t)
        out[0].y = (a[0].y * (1 - t) + b[0].y * t)
        out[0].z = (a[0].z * (1 - t) + b[0].z * t)
    }
    
    static func vectorScale(v:UnsafeMutablePointer<Vec3>, scale:Float) {
        v[0].x *= scale
        v[0].y *= scale
        v[0].z *= scale
    }
    
    static func vectorInverse(v:UnsafeMutablePointer<Vec3>) {
        v[0].x = -v[0].x
        v[0].y = -v[0].y
        v[0].z = -v[0].z
    }
    
    static func vectorNormalize(v:UnsafeMutablePointer<Vec3>) {
        var length = Vector.vectorLength(into: v)
        if length != 0 {
            length = 1 / length
            v[0].x *= length
            v[0].y *= length
            v[0].z *= length
        }
    }
    
    static func vectorCompare(a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) -> Int {
        if a == b {return 1}
        if a[0].x != b[0].x || a[0].y != b[0].y || a[0].z != b[0].z { return 0 }
        return 1
    }
    
    
    static func vectorLength(into:UnsafePointer<Vec3>) ->Float {
        return sqrt(into[0].x * into[0].x + into[0].y * into[0].y + into[0].z * into[0].z)
    }
    
    static func vectorLengthSquared(into:UnsafePointer<Vec3>) -> Float {
        return (into[0].x * into[0].x + into[0].y * into[0].y + into[0].z * into[0].z)
    }
    
    static func vectorDistance(a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) -> Float {
        var v = Vec3(x: 0, y: 0, z: 0)
        Vector.vectorSubtract(out: &v, a: a, b: b)
        return Vector.vectorLength(into: &v)
    }
    
    static func vectorDistanceSquared(a:UnsafePointer<Vec3>, b:UnsafePointer<Vec3>) -> Float {
        var v = Vec3(x: 0, y: 0, z: 0)
        Vector.vectorSubtract(out: &v, a: a, b: b)
        return (v.x * v.x + v.y * v.y + v.z * v.z)
    }
}
