//
//  Material.swift
//  Toturial-09-obj
//
//  Created by mkil on 2019/6/19.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import Foundation

public struct Color {
    public static let Black = Color(r: 0.0, g: 0.0, b: 0.0)
    
    public let r: Double
    public let g: Double
    public let b: Double
}

class MaterialBuilder {
    var name: String = ""
    var ambientColor: Color?
    var diffuseColor: Color?
    var specularColor: Color?
    var illuminationModel: IlluminationModel?
    var specularExponent: Double?
    var ambientTextureMapFilePath: String?
    var diffuseTextureMapFilePath: String?
}


public final class Material {
    public let name: String
    public let ambientColor: Color
    public let diffuseColor: Color
    public let specularColor: Color
    public let illuminationModel: IlluminationModel
    public let specularExponent: Double?
    public let ambientTextureMapFilePath: String?
    public let diffuseTextureMapFilePath: String?
    
    init(builderBlock: (MaterialBuilder) -> MaterialBuilder) {
        let builder = builderBlock(MaterialBuilder())
        
        self.name = builder.name
        self.ambientColor = builder.ambientColor ?? Color.Black
        self.diffuseColor = builder.diffuseColor ?? Color.Black
        self.specularColor = builder.specularColor ?? Color.Black
        self.illuminationModel = builder.illuminationModel ?? .constant
        self.specularExponent = builder.specularExponent
        self.ambientTextureMapFilePath = builder.ambientTextureMapFilePath
        self.diffuseTextureMapFilePath = builder.diffuseTextureMapFilePath
    }
}

public enum IlluminationModel: Int {
    case constant = 0
    case diffuse = 1
    case diffuseSpecular = 2
}
