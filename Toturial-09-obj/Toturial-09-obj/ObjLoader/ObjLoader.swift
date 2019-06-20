//
//  ObjLoader.swift
//  ObjTest
//
//  Created by mkil on 2019/6/14.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation
import GLKit

enum ObjLoadingError: Error {
    case unexpectedFileFormat(error: String)
}

public final class ObjLoader {
    
    class Database {
        var objectName: NSString?
        var vertices: [Double] = []
        var normals: [Double] = []
        var textureCoords: [Double] = []
        
        // 三角面 索引
        var vertexIndexs: [Int] = []
        var textureIndexs: [Int] = []
        var normalIndexs: [Int] = []
        
        // 顶点 纹理 法线  合并数据
        var mergeVertices: [GLfloat] = []
        
        // 纹理数据
        var material: Material?
    }
    
    fileprivate static let commentMarker = "#"
    fileprivate static let vertexMarker = "v"
    fileprivate static let normalMarker = "vn"
    fileprivate static let textureCoordMarker = "vt"
    fileprivate static let faceMarker = "f"
    fileprivate static let materialLibraryMarker = "mtllib"
    fileprivate static let useMaterialMarker = "usemtl"
    
    fileprivate let scanner: ObjScanner
    fileprivate let basePath: String
    fileprivate var materialCache: [String: Material] = [:]
    
    var data = Database()
    
    public init(source: String, basePath: String) {
        scanner = ObjScanner(source: source)
        self.basePath = basePath
    }
    
    public func read() throws -> Void {
        resetState()
        do {
            while !scanner.isAtEnd {
                let marker = scanner.readMarker()
                
                guard let m = marker, m.length > 0 else {
                    scanner.moveToNextLine()
                    continue
                }
                
                let markerString = m as String
                
                if ObjLoader.isComment(markerString) {
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isVertex(markerString) {
                    if let v = try readVertex() {
                        data.vertices.append(contentsOf: v)
                    }
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isNormal(markerString) {
                    if let n = try readVertex() {
                        data.normals.append(contentsOf: n)
                    }
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isTextureCoord(markerString) {

                    if let vt = try readTextureCoord() {
                        data.textureCoords.append(contentsOf: vt)
                    }
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isFace(markerString) {
                    
                    if let results = try scanner.readFace() {
                        data.vertexIndexs.append(results[0])
                        data.vertexIndexs.append(results[3])
                        data.vertexIndexs.append(results[6])
                        
                        data.textureIndexs.append(results[1])
                        data.textureIndexs.append(results[4])
                        data.textureIndexs.append(results[7])
                        
                        data.normalIndexs.append(results[2])
                        data.normalIndexs.append(results[5])
                        data.normalIndexs.append(results[8])
                    }
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isMaterialLibrary(markerString) {
                    let filenames = try scanner.readTokens()
                    try parseMaterialFiles(filenames)
                    scanner.moveToNextLine()
                    continue
                }
                
                if ObjLoader.isUseMaterial(markerString) {
                    let materialName = try scanner.readString() as String
                    
                    guard let material = self.materialCache[materialName] else {
                        throw ObjLoadingError.unexpectedFileFormat(error: "Material \(materialName) referenced before it was definied")
                    }
                    
                    data.material = material
                    scanner.moveToNextLine()
                }
                scanner.moveToNextLine()
            }
        
            mergeData()
            
        } catch let e {
            resetState()
            throw e
        }
    }
}

extension ObjLoader {

    // 整合 顶点(x, y, z) 纹理 (u, v)  法线 (nx, ny, nz)
    fileprivate func mergeData() {
        
        for i in 0..<data.vertexIndexs.count {
            
            let vertexIndex = (data.vertexIndexs[i]-1) * 3
            for value in data.vertices[vertexIndex..<(vertexIndex + 3)] {
                data.mergeVertices.append(GLfloat(value))
            }

            let textureIndex = (data.textureIndexs[i]-1) * 2
            for value in data.textureCoords[textureIndex..<(textureIndex + 2)] {
                data.mergeVertices.append(GLfloat(value))
            }
            
            let normalIndex = (data.normalIndexs[i]-1) * 3
            for value in data.normals[normalIndex..<(normalIndex + 3)] {
                data.mergeVertices.append(GLfloat(value))
            }
        }
        
    }
    
    // 读取顶点数据
    fileprivate func readVertex() throws -> [Double]? {
        do {
            return try scanner.readVertex()
        } catch ScannerErrors.unreadableData(let error) {
            throw ObjLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    // 读取纹理数据
    fileprivate func readTextureCoord() throws -> [Double]? {
        do {
          return try scanner.readTextureCoord()
        } catch ScannerErrors.unreadableData(let error) {
            throw ObjLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    fileprivate static func isComment(_ marker: String) -> Bool {
        return marker == commentMarker
    }
    
    fileprivate static func isVertex(_ marker: String) -> Bool {
        return marker.count == 1 && marker == vertexMarker
    }
    
    fileprivate static func isNormal(_ marker: String) -> Bool {
        return marker.count == 2 && marker == normalMarker
    }
    
    fileprivate static func isTextureCoord(_ marker: String) -> Bool {
        return marker.count == 2 && marker == textureCoordMarker
    }
    
    fileprivate static func isFace(_ marker: String) ->Bool {
        return marker.count == 1 && marker == faceMarker
    }
    
    fileprivate static func isMaterialLibrary(_ marker: String) -> Bool {
        return marker  == materialLibraryMarker
    }
    
    fileprivate static func isUseMaterial(_ marker: String) -> Bool {
        return marker == useMaterialMarker
    }
    
    fileprivate func resetState() {
        scanner.reset()
        data = Database()
    }
    
    fileprivate func parseMaterialFiles(_ filenames: [NSString]) throws {
        for filename in filenames {
            let fullPath = basePath + "/" + (filename as String)
            
            do {
                let fileContents = try String(contentsOfFile: fullPath, encoding: String.Encoding.utf8)
                
                let loader = MaterialLoader(source: fileContents,
                                            basePath: basePath)
                let materials = try loader.read()
                for material in materials {
                    materialCache[material.name] = material
                }
            } catch MaterialLoadingError.unexpectedFileFormat(let msg) {
                throw ObjLoadingError.unexpectedFileFormat(error: msg)
            } catch {
                throw ObjLoadingError.unexpectedFileFormat(error: "Invalid material file at \(fullPath)")
            }
        }
    }
    
    
}
