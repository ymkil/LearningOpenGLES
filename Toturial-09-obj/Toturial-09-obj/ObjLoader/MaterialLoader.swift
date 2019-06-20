//
//  MaterialLoader.swift
//  Toturial-09-obj
//
//  Created by mkil on 2019/6/19.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation

public enum MaterialLoadingError: Error {
    case unexpectedFileFormat(error: String)
}

public final class MaterialLoader {
    
    struct Temp {
        var materialName: String?
        var ambientColor: Color?
        var diffuseColor: Color?
        var specularColor: Color?
        var specularExponent: Double?
        var illuminationModel: IlluminationModel?
        var ambientTextureMapFilePath: String?
        var diffuseTextureMapFilePath: String?
        
        func isDirty() -> Bool {
            if materialName != nil {
                return true
            }
            
            if ambientColor != nil {
                return true
            }
            
            if diffuseColor != nil {
                return true
            }
            
            if specularColor != nil {
                return true
            }
            
            if specularExponent != nil {
                return true
            }
            
            if illuminationModel != nil {
                return true
            }
            
            if ambientTextureMapFilePath != nil {
                return true
            }
            
            if diffuseTextureMapFilePath != nil {
                return true
            }
            
            return false
        }
    }
    
    fileprivate static let newMaterialMarker       = "newmtl"
    fileprivate static let ambientColorMarker      = "Ka"
    fileprivate static let diffuseColorMarker      = "Kd"
    fileprivate static let specularColorMarker     = "Ks"
    fileprivate static let specularExponentMarker  = "Ns"
    fileprivate static let illuminationModeMarker  = "illum"
    fileprivate static let ambientTextureMapMarker = "map_Ka"
    fileprivate static let diffuseTextureMapMarker = "map_Kd"
    
    fileprivate let scanner: MaterialScanner
    fileprivate let basePath: String
    fileprivate var temp: Temp
    
    init(source: String, basePath: String) {
        self.basePath = basePath
        scanner = MaterialScanner(source: source)
        temp = Temp()
    }
    
    func read() throws -> [Material] {
        resetState()
        var materials: [Material] = []
        
        do {
            while !scanner.isAtEnd {
                let marker = scanner.readMarker()
                
                guard let m = marker, m.length > 0 else {
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isAmbientColor(m) {
                    let color = try readColor()
                    temp.ambientColor = color
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isDiffuseColor(m) {
                    let color = try readColor()
                    temp.diffuseColor = color
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isSpecularColor(m) {
                    let color = try readColor()
                    temp.specularColor = color
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isSpecularExponent(m) {
                    let specularExponent = try readSpecularExponent()
                    
                    temp.specularExponent = specularExponent
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isIlluminationMode(m) {
                    let model = try readIlluminationModel()
                    temp.illuminationModel = model
                    
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isAmbientTextureMap(m) {
                    let mapFilename = try readFilename()
                    temp.ambientTextureMapFilePath = basePath + "/" + (mapFilename as String)
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isDiffuseTextureMap(m) {
                    let mapFilename = try readFilename()
                    temp.diffuseTextureMapFilePath = basePath + "/" + (mapFilename as String)
                    scanner.moveToNextLine()
                    continue
                }
                
                if MaterialLoader.isNewMaterial(m) {
                    if let material = try buildMaterial() {
                        materials.append(material)
                    }
                    
                    temp = Temp()
                    temp.materialName = scanner.readLine() as! String
                    scanner.moveToNextLine()
                    continue
                }
                scanner.readLine()
                scanner.moveToNextLine()
                continue
            }
            
            if let material = try buildMaterial() {
                materials.append(material)
            }
            
            temp = Temp()
        }
        
        return materials
    }
    
    fileprivate func resetState() {
        scanner.reset()
        temp = Temp()
    }
    
    fileprivate static func isNewMaterial(_ marker: NSString) -> Bool {
        return marker as String == newMaterialMarker
    }
    
    fileprivate static func isAmbientColor(_ marker: NSString) -> Bool {
        return marker as String == ambientColorMarker
    }
    
    fileprivate static func isDiffuseColor(_ marker: NSString) -> Bool {
        return marker as String == diffuseColorMarker
    }
    
    fileprivate static func isSpecularColor(_ marker: NSString) -> Bool {
        return marker as String == specularColorMarker
    }
    
    fileprivate static func isSpecularExponent(_ marker: NSString) -> Bool {
        return marker as String == specularExponentMarker
    }
    
    fileprivate static func isIlluminationMode(_ marker: NSString) -> Bool {
        return marker as String == illuminationModeMarker
    }
    
    fileprivate static func isAmbientTextureMap(_ marker: NSString) -> Bool {
        return marker as String == ambientTextureMapMarker
    }
    
    fileprivate static func isDiffuseTextureMap(_ marker: NSString) -> Bool {
        return marker as String == diffuseTextureMapMarker
    }

    
    fileprivate func readColor() throws -> Color {
        do {
            return try scanner.readColor()
        } catch ScannerErrors.invalidData(let error) {
            throw MaterialLoadingError.unexpectedFileFormat(error: error)
        } catch ScannerErrors.unreadableData(let error) {
            throw MaterialLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    fileprivate func readIlluminationModel() throws -> IlluminationModel {
        do {
            let value = try scanner.readInt()
            if let model = IlluminationModel(rawValue: Int(value)) {
                return model
            }
            
            throw MaterialLoadingError.unexpectedFileFormat(error: "Invalid illumination model: \(value)")
        } catch ScannerErrors.invalidData(let error) {
            throw MaterialLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    fileprivate func readSpecularExponent() throws -> Double {
        do {
            let value = try scanner.readDouble()
            
            guard value >= 0.0 && value <= 1000.0 else {
                throw MaterialLoadingError.unexpectedFileFormat(error: "Invalid Ns value: !(value)")
            }
            
            return value
        } catch ScannerErrors.invalidData(let error) {
            throw MaterialLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    fileprivate func readFilename() throws -> NSString {
        do {
            return try scanner.readString()
        } catch ScannerErrors.invalidData(let error) {
            throw MaterialLoadingError.unexpectedFileFormat(error: error)
        }
    }
    
    fileprivate func buildMaterial() throws -> Material? {
        guard temp.isDirty() else {
            return nil
        }
        
        guard let name = temp.materialName else {
            throw MaterialLoadingError.unexpectedFileFormat(error: "Material name required for all materials")
        }
        
        return Material() {
            $0.name              = name
            $0.ambientColor      = self.temp.ambientColor
            $0.diffuseColor      = self.temp.diffuseColor
            $0.specularColor     = self.temp.specularColor
            $0.specularExponent  = self.temp.specularExponent
            $0.illuminationModel = self.temp.illuminationModel
            $0.ambientTextureMapFilePath = self.temp.ambientTextureMapFilePath
            $0.diffuseTextureMapFilePath = self.temp.diffuseTextureMapFilePath
            
            return $0
        }
    }
}

