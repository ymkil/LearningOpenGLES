//
//  Matrix.swift
//  OpenGL-ES-05
//
//  Created by mkil on 2019/1/14.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation
import OpenGLES

public struct MatrixArray<T> {
    public let columns: Int
    public let rows: Int
    public var array: [T]
    
    public init(rows: Int, columns: Int, initialValue: T) {
        self.rows = rows
        self.columns = columns
        array = .init(repeating: initialValue, count: rows*columns)
    }
    
    public subscript(row: Int, column: Int) -> T {
        get {
            return array[row*columns + column]
        }
        set {
            array[row*columns + column] = newValue
        }
    }
    
    static func memset(resultM4 result: UnsafeMutablePointer<MatrixArray<T>>, initialValue:T) {
        for i in 0..<result[0].rows {
            for j in 0..<result[0].columns {
                result[0][i,j] = initialValue
            }
        }
    }
}


public struct Matrix {
    
    static func matrix3(_ initialValue: Float = 0) -> MatrixArray<Float> {
        return MatrixArray(rows: 3, columns: 3, initialValue: initialValue)
    }
    
    static func matrix4(_ initialValue: Float = 0) -> MatrixArray<Float> {
        return MatrixArray(rows: 4, columns: 4, initialValue: initialValue)
    }
    
    //
    /// multiply matrix specified by result with a scaling matrix and return new matrix in result
    /// result Specifies the input matrix.  Scaled matrix is returned in result.
    /// sx, sy, sz Scale factors along the x, y and z axes respectively
    //
    
    static func matrixScale(matrix4 result: UnsafeMutablePointer<MatrixArray<Float>>, sx: Float, sy: Float, sz: Float) {
        
        result[0][0,0] *= sx
        result[0][0,1] *= sx
        result[0][0,2] *= sx
        result[0][0,3] *= sx
        
        result[0][1,0] *= sy
        result[0][1,1] *= sy
        result[0][1,2] *= sy
        result[0][1,3] *= sy
        
        result[0][2,0] *= sz
        result[0][2,1] *= sz
        result[0][2,2] *= sz
        result[0][2,3] *= sz
    }
    
    
    //
    /// multiply matrix specified by result with a translation matrix and return new matrix in result
    /// result Specifies the input matrix.  Translated matrix is returned in result.
    /// tx, ty, tz Scale factors along the x, y and z axes respectively
    //
    
    static func matrixTranslate(resultM4 result: UnsafeMutablePointer<MatrixArray<Float>>, tx:Float, ty:Float, tz:Float) {
 
        result[0][3,0] += (result[0][0,0] * tx + result[0][1,0] * ty + result[0][2,0] * tz)
        result[0][3,1] += (result[0][0,1] * tx + result[0][1,1] * ty + result[0][2,1] * tz)
        result[0][3,2] += (result[0][0,2] * tx + result[0][1,2] * ty + result[0][2,2] * tz)
        result[0][3,3] += (result[0][0,3] * tx + result[0][1,3] * ty + result[0][2,3] * tz)

    }
    
    //
    /// multiply matrix specified by result with a rotation matrix and return new matrix in result
    /// result Specifies the input matrix.  Rotated matrix is returned in result.
    /// angle Specifies the angle of rotation, in degrees.
    /// x, y, z Specify the x, y and z coordinates of a vector, respectively
    //
    
    static func matrixRotate(resultM4 result: UnsafeMutablePointer<MatrixArray<Float>>, angle:Float, x:Float, y:Float, z:Float) {
        
        var sinAngle:Float, cosAngle:Float 
        let mag = sqrtf(x * x + y * y + z * z)
        
        sinAngle = sinf(angle * Float.pi / 180)
        cosAngle = cosf(angle * Float.pi / 180)
        
        if mag > 0 {
            var xx:Float, yy:Float, zz:Float, xy:Float, yz:Float, zx:Float, xs:Float, ys:Float, zs:Float
            
            var oneMinusCos:Float
            var rotMat = Matrix.matrix4(0)
            
            let newx = x/mag
            let newy = y/mag
            let newz = z/mag
            
            xx = newx * newx
            yy = newy * newy
            zz = newz * newz
            
            xy = newx * newy
            yz = newy * newz
            zx = newz * newx
            
            xs = newx * sinAngle
            ys = newy * sinAngle
            zs = newz * sinAngle
            oneMinusCos = 1 - cosAngle
            
            rotMat[0,0] = (oneMinusCos * xx) + cosAngle;
            rotMat[0,1] = (oneMinusCos * xy) - zs;
            rotMat[0,2] = (oneMinusCos * zx) + ys;
            rotMat[0,3] = 0.0;
            
            rotMat[1,0] = (oneMinusCos * xy) + zs;
            rotMat[1,1] = (oneMinusCos * yy) + cosAngle;
            rotMat[1,2] = (oneMinusCos * yz) - xs;
            rotMat[1,3] = 0.0;
            
            rotMat[2,0] = (oneMinusCos * zx) - ys;
            rotMat[2,1] = (oneMinusCos * yz) + xs;
            rotMat[2,2] = (oneMinusCos * zz) + cosAngle;
            rotMat[2,3] = 0.0;
            
            rotMat[3,0] = 0.0;
            rotMat[3,1] = 0.0;
            rotMat[3,2] = 0.0;
            rotMat[3,3] = 1.0;
            
            Matrix.matrixMultiply(resultM4: result, aM4: &rotMat, bM4: result)
        }
    }
    
    
    //
    /// perform the following operation - result matrix = srcA matrix * srcB matrix
    /// result Returns multiplied matrix
    /// srcA, srcB Input matrices to be multiplied
    //
    
    static func matrixMultiply(resultM4 result: UnsafeMutablePointer<MatrixArray<Float>>, aM4 a:UnsafePointer<MatrixArray<Float>>, bM4 b:UnsafePointer<MatrixArray<Float>>) {
        
        var tmp = Matrix.matrix4(0)
        for i in 0..<4 {
            tmp[i,0] = (a[0][i,0] * b[0][0,0]) +
                (a[0][i,1] * b[0][1,0]) +
                (a[0][i,2] * b[0][2,0]) +
                (a[0][i,3] * b[0][3,0])
                
            tmp[i,1] = (a[0][i,0] * b[0][0,1]) +
                (a[0][i,1] * b[0][1,1]) +
                (a[0][i,2] * b[0][2,1]) +
                (a[0][i,3] * b[0][3,1])
            
            tmp[i,2] = (a[0][i,0] * b[0][0,2]) +
                (a[0][i,1] * b[0][1,2]) +
                (a[0][i,2] * b[0][2,2]) +
                (a[0][i,3] * b[0][3,2])
            
            tmp[i,3] = (a[0][i,0] * b[0][0,3]) +
                (a[0][i,1] * b[0][1,3]) +
                (a[0][i,2] * b[0][2,3]) +
                (a[0][i,3] * b[0][3,3])
        }
        
        result[0] = tmp
    }
    
    //
    //// return an identity matrix
    //// result returns identity matrix
    //
    
    static func matrixLoadIdentity(resultM4 result:UnsafeMutablePointer<MatrixArray<Float>>) {
        MatrixArray<Float>.memset(resultM4: result,initialValue: 0)
        result[0][0,0] = 1
        result[0][1,1] = 1
        result[0][2,2] = 1
        result[0][3,3] = 1
    }
    
    
    /// multiply matrix specified by result with a perspective matrix and return new matrix in result
    /// result Specifies the input matrix.  new matrix is returned in result.
    /// fovy Field of view y angle in degrees
    /// aspect Aspect ratio of screen
    /// nearZ Near plane distance
    /// farZ Far plane distance
    //
    
    static func perspective(resultM4 result:UnsafeMutablePointer<MatrixArray<Float>>, _ fovy:Float, _ aspect:Float, _ nearZ:Float, _ farZ:Float) {
        
        let frustumH = tanf(fovy / 360 * Float.pi) * nearZ
        let frustumW = frustumH * aspect
        Matrix.frustum(resultM4: result, -frustumW, frustumW, -frustumH, frustumH, nearZ, farZ)
    }
    
    //
    /// multiply matrix specified by result with a perspective matrix and return new matrix in result
    /// result Specifies the input matrix.  new matrix is returned in result.
    /// left, right Coordinates for the left and right vertical clipping planes
    /// bottom, top Coordinates for the bottom and top horizontal clipping planes
    /// nearZ, farZ Distances to the near and far depth clipping planes.  These values are negative if plane is behind the viewer
    //
    
    static func ortho(resultM4 result:UnsafeMutablePointer<MatrixArray<Float>>, _ left:Float, _ right:Float, _ bottom:Float, _ top:Float, _ nearZ:Float, _ farZ:Float) {
        
        let deltaX = right - left;
        let deltaY = top - bottom;
        let deltaZ = farZ - nearZ;
        
        var ortho = Matrix.matrix4(0)
        
        if deltaX == 0 || deltaY == 0 || deltaZ == 0 { return }
        
        Matrix.matrixLoadIdentity(resultM4: &ortho)
        ortho[0,0] = 2 / deltaX
        ortho[3,0] = -(right + left) / deltaX
        ortho[1,1] = 2 / deltaY
        ortho[3,1] = -(top + bottom) / deltaY
        ortho[2,2] = 2 / deltaZ
        ortho[3,2] = -(nearZ + farZ) / deltaZ
        
        Matrix.matrixMultiply(resultM4: result, aM4: &ortho, bM4: result)
    }
    
    
    
    
    //
    // multiply matrix specified by result with a perspective matrix and return new matrix in result
    /// result Specifies the input matrix.  new matrix is returned in result.
    /// left, right Coordinates for the left and right vertical clipping planes
    /// bottom, top Coordinates for the bottom and top horizontal clipping planes
    /// nearZ, farZ Distances to the near and far depth clipping planes.  Both distances must be positive.
    //
    
    static func frustum(resultM4 result:UnsafeMutablePointer<MatrixArray<Float>>, _ left:Float, _ right:Float, _ bottom:Float, _ top:Float, _ nearZ:Float, _ farZ:Float)
    {
        let deltaX = right - left;
        let deltaY = top - bottom;
        let deltaZ = farZ - nearZ;
        
        var frust = Matrix.matrix4(0)
        
        if nearZ <= 0 || farZ <= 0 || deltaX <= 0 || deltaY <= 0 || deltaZ <= 0 {
            return
        }
        
        frust[0,0] = 2 * nearZ / deltaX
        frust[0,1] = 0
        frust[0,2] = 0
        frust[0,3] = 0
        
        frust[1,1] = 2 * nearZ / deltaY
        frust[1,0] = 0
        frust[1,2] = 0
        frust[1,3] = 0
        
        frust[2,0] = (right + left) / deltaX
        frust[2,1] = (top + bottom) / deltaY
        frust[2,2] = -(nearZ + farZ) / deltaZ
        frust[2,3] = -1
        
        frust[3,2] = -2 * nearZ * farZ / deltaZ
        frust[3,0] = 0
        frust[3,1] = 0
        frust[3,3] = 0
        Matrix.matrixMultiply(resultM4: result, aM4: &frust, bM4: result)
    }
    
    static func lookAt(resultM4 result:UnsafeMutablePointer<MatrixArray<Float>>, eye:UnsafePointer<Vec3>, target:UnsafePointer<Vec3>, up:UnsafePointer<Vec3>) {
        
        var side = Vec3(x: 0, y: 0, z: 0)
        var up2 = Vec3(x: 0, y: 0, z: 0)
        var forward = Vec3(x: 0, y: 0, z: 0)
        
        var transMat = Matrix.matrix4(0)
        
        Vector.vectorSubtract(out: &forward, a: target, b: eye)
        Vector.vectorNormalize(v: &forward)
        
        Vector.crossProduct(out: &side, a: up, b: &forward)
        Vector.vectorNormalize(v: &side)
        
        Vector.crossProduct(out: &up2, a: &side, b: &forward)
        Vector.vectorNormalize(v: &up2)
        
        Matrix.matrixLoadIdentity(resultM4: result)
        result[0][0,0] = side.x
        result[0][0,1] = side.y
        result[0][0,2] = side.z
        result[0][1,0] = up2.x
        result[0][1,1] = up2.y
        result[0][1,2] = up2.z
        result[0][2,0] = -forward.x
        result[0][2,1] = -forward.y
        result[0][2,2] = -forward.z
        
        Matrix.matrixLoadIdentity(resultM4: &transMat)
        Matrix.matrixTranslate(resultM4: &transMat, tx: -eye[0].x, ty: -eye[0].y, tz: -eye[0].z)
        
        Matrix.matrixMultiply(resultM4: result, aM4: result, bM4: &transMat)
    }
}
