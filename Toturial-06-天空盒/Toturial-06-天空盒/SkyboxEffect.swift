//
//  SkyboxEffect.swift
//  Toturial-06-天空盒
//
//  Created by mkil on 2019/5/11.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import GLKit

class SkyboxEffect {
    
    var skyBoxProgram: GLuint?
    
    var skyBoxVAOId: GLuint = 0
    var skyBoxVBOId: GLuint = 0
    
    var skyBoxTextId: GLuint = 0
    
    var center:GLKVector3 = GLKVector3Make(0, 0, 0)
    var xSize: GLfloat = 1
    var ySize: GLfloat = 1
    var zSize: GLfloat = 1
    
    var transform = GLKEffectPropertyTransform()
    
    init() {
        setupProgram()
        setupVBOAndVAO()
        setupTexure()
    }
}


extension SkyboxEffect {
    
    public func prepareToDraw() {
        guard let skyBoxProgram = skyBoxProgram else {
            return
        }
        
        glUseProgram(skyBoxProgram)
        
        var modelView = GLKMatrix4Translate(transform.modelviewMatrix, center.x, center.y, center.z)
        modelView = GLKMatrix4Scale(modelView, xSize, ySize, zSize)
        
        let modelViewProjection = GLKMatrix4Multiply(transform.projectionMatrix, modelView)
        
        glUniformMatrix4fv(glGetUniformLocation(skyBoxProgram, "u_mvpMatrix"), 1, GLboolean(GL_FALSE), modelViewProjection.array)
    }
    
    public func draw() {
        guard let skyBoxProgram = skyBoxProgram else {
            return
        }
        glBindVertexArray(skyBoxVAOId)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), skyBoxTextId)
        glUniform1i(glGetUniformLocation(skyBoxProgram,"skybox"), 0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
    }
}


extension SkyboxEffect {
    
    fileprivate func setupProgram() {
    
        skyBoxProgram = GLESUtils.loanProgram(verShaderFileName: "skyboxv.glsl", fragShaderFileName: "skyboxf.glsl")
        
        guard let skyBoxProgram = skyBoxProgram else {
            return
        }
        glUseProgram(skyBoxProgram)
    }

    fileprivate func setupVBOAndVAO() {
        
        // 指定包围盒的顶点属性 位置
        let skyboxVertices: [GLfloat] = [
            // 背面
            -1.0, 1.0, -1.0,        // A
            -1.0, -1.0, -1.0,    // B
            1.0, -1.0, -1.0,        // C
            1.0, -1.0, -1.0,        // C
            1.0, 1.0, -1.0,        // D
            -1.0, 1.0, -1.0,        // A
            
            // 左侧面
            -1.0, -1.0, 1.0,        // E
            -1.0, -1.0, -1.0,    // B
            -1.0, 1.0, -1.0,        // A
            -1.0, 1.0, -1.0,        // A
            -1.0, 1.0, 1.0,        // F
            -1.0, -1.0, 1.0,        // E
            
            // 右侧面
            1.0, -1.0, -1.0,        // C
            1.0, -1.0, 1.0,        // G
            1.0, 1.0, 1.0,        // H
            1.0, 1.0, 1.0,        // H
            1.0, 1.0, -1.0,        // D
            1.0, -1.0, -1.0,        // C
            
            // 正面
            -1.0, -1.0, 1.0,  // E
            -1.0, 1.0, 1.0,  // F
            1.0, 1.0, 1.0,  // H
            1.0, 1.0, 1.0,  // H
            1.0, -1.0, 1.0,  // G
            -1.0, -1.0, 1.0,  // E
            
            // 顶面
            -1.0, 1.0, -1.0,  // A
            1.0, 1.0, -1.0,  // D
            1.0, 1.0, 1.0,  // H
            1.0, 1.0, 1.0,  // H
            -1.0, 1.0, 1.0,  // F
            -1.0, 1.0, -1.0,  // A
            
            // 底面
            -1.0, -1.0, -1.0,  // B
            -1.0, -1.0, 1.0,   // E
            1.0, -1.0, 1.0,    // G
            1.0, -1.0, 1.0,    // G
            1.0, -1.0, -1.0,   // C
            -1.0, -1.0, -1.0,  // B
        ]
        
        guard let skyBoxProgram = skyBoxProgram else {
            return
        }
        
        glGenVertexArrays(1, &skyBoxVAOId)
        glGenBuffers(1, &skyBoxVBOId)
        glBindVertexArray(skyBoxVAOId)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), skyBoxVBOId)
        glBufferData(GLenum(GL_ARRAY_BUFFER), skyboxVertices.count * MemoryLayout<GLfloat>.size, skyboxVertices, GLenum(GL_STATIC_DRAW))
        
        // 顶点位置数据
        glVertexAttribPointer(
            GLuint(glGetAttribLocation(skyBoxProgram, "position")),
            3,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 3), UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(skyBoxProgram, "position")))
        glBindVertexArray(0)
        
    }
    
    fileprivate func setupTexure() {
        let skyboxvImages = ["fadeaway_rt.tga","fadeaway_lf.tga","fadeaway_up.tga",
                             "fadeaway_dn.tga","fadeaway_bk.tga","fadeaway_ft.tga"]
        skyBoxTextId = loadCubeMapTexture(fileNames: skyboxvImages)
    }
    
    fileprivate func loadCubeMapTexture(fileNames:[String]) -> GLuint {
        
        var textId: GLuint = 0
        glGenTextures(1, &textId)
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), textId)
        
        
        
        for (index,name) in fileNames.enumerated() {
            guard let spriteImage = UIImage(named: name)?.cgImage else {
                print("Failed to load image \(name)")
                return textId
            }
            
            // 读取图片大小
            let width = spriteImage.width
            let height = spriteImage.height
            
            let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
            
            let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            // 3在CGContextRef上绘图
            spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            glTexImage2D(GLenum(GL_TEXTURE_CUBE_MAP_POSITIVE_X + Int32(index)), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData)
            free(spriteData)
        }
        
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_CUBE_MAP), GLenum(GL_TEXTURE_WRAP_R), GL_CLAMP_TO_EDGE)
        
        glBindTexture(GLenum(GL_TEXTURE_CUBE_MAP), 0)
        
        return textId
    }
    
    
    
}
