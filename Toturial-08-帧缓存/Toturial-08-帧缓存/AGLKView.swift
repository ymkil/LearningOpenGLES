//
//  AGLKView.swift
//  Toturial-08-帧缓存
//
//  Created by mkil on 2019/6/9.
//  Copyright © 2019 mkil. All rights reserved.
//

import UIKit
import GLKit

class AGLKView: UIView {
    
    var presentContex: EAGLContext?
    
    var frameBuffer: GLuint = 0 // 默认帧缓存
    var colorRenderBuffer: GLuint = 0
    var depthRenderBuffer: GLuint = 0
    
    var frameBuffer1: GLuint = 0
    var frameBuffer1Size: CGSize = CGSize(width: 256, height: 256)
    
    var program: GLuint?
    var program1: GLuint?
    
    var vbo: GLuint = 0
    var vbo1: GLuint = 0
    
    var textId: GLuint = 0
    var fboTextId: GLuint = 0
    
    // 只有CAEAGLLayer 类型的 layer 才支持 OpenGl 描绘
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupContext()
        setupProgram()
        setupVBO()
        setupVBO1()
        setupTexure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        EAGLContext.setCurrent(presentContex)
        destoryRenderAndFrameBuffer()
        setupBuffer()
        setupBuffer1()
        
        render()
    }
}


extension AGLKView {
    fileprivate func render() {
        
        guard let program = program, let program1 = program1 else {
            return
        }
        
        glUseProgram(program1)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer1)

        glClearColor(1.0, 1.0, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        glViewport(0, 0, GLsizei(frameBuffer1Size.width), GLsizei(frameBuffer1Size.height))
        
        glBindVertexArray(vbo1)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
        glUniform1i(glGetUniformLocation(program1,"u_Texture"), 0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        glUseProgram(program)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        
        glClearColor(0.0, 1.0, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        glBindVertexArray(vbo)
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), fboTextId)
        glUniform1i(glGetUniformLocation(program1,"u_Texture"), 1)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        presentContex?.presentRenderbuffer(Int(GL_RENDERBUFFER))

    }
}

extension AGLKView {
    fileprivate func setupLayer() {
        let eagLayer = layer as? CAEAGLLayer
        
        // CALayer 默认是透明的，必须将它设为不透明才能让其可见
        eagLayer?.isOpaque = true
        // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
        eagLayer?.drawableProperties = [kEAGLDrawablePropertyRetainedBacking:false,kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
    }
    
    fileprivate func setupContext() {
        // 指定 OpenGL 渲染 API 的版本，在这里我们使用 OpenGL ES 3.0
        presentContex = EAGLContext(api: .openGLES3)
        
        if presentContex == nil {
            print("Failed to initialize OpenGLES 3.0 context")
            return
        }
        // 设置为当前上下文
        if !EAGLContext.setCurrent(presentContex) {
            print("Failed to set current OpenGL context")
            return
        }
    }
    
    
    fileprivate func destoryRenderAndFrameBuffer() {
        glDeleteFramebuffers(1, &frameBuffer)
        frameBuffer = 0
        glDeleteRenderbuffers(1, &colorRenderBuffer)
        colorRenderBuffer = 0
    }
    
    fileprivate func setupBuffer() {
        
        // 窗口默认帧缓存
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        presentContex?.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer as? CAEAGLLayer)
        
        var width: GLint = 0
        var height: GLint = 0
        
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &width)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &height)
        
        // 创建深度缓冲区
        glGenRenderbuffers(1, &depthRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthRenderBuffer)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), width, height)
        
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderBuffer)
        
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
    }
    
    fileprivate func setupBuffer1() {
     
        glGenTextures(1, &fboTextId)
        glBindTexture(GLenum(GL_TEXTURE_2D), fboTextId)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(frameBuffer1Size.width), GLsizei(frameBuffer1Size.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        
        glGenFramebuffers(1, &frameBuffer1)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer1)
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), fboTextId, 0)
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        
        if status == GL_FRAMEBUFFER_COMPLETE {
            print("fbo complete width \(frameBuffer1Size.width) height \(frameBuffer1Size.height)")
        } else if status == GL_FRAMEBUFFER_UNSUPPORTED {
            print("fbo unsupported")
        } else {
            print("Framebuffer Error")
        }
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }
    
    fileprivate func setupProgram() {
        program = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
        program1 = GLESUtils.loanProgram(verShaderFileName: "shaderFBOv.glsl", fragShaderFileName: "shaderf.glsl")
    }
    
    fileprivate func setupVBO() {
        let vertices: [GLfloat] = [
            0.5, 0.5, -1,       1, 1,   // 右上               1, 0
            0.5, -0.5, -1,      1, 0,   // 右下               1, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, 0.5, -1,      0, 1,   // 左上               0, 0
            0.5, 0.5, -1,       1, 1    // 右上               1, 0
        ]
        
        guard let targetProgram = program else {
            return
        }
        
        glGenBuffers(1, &vbo)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLfloat>.size, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_position")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
    }
    
    fileprivate func setupVBO1() {
        let vertices: [GLfloat] = [
            0.5, 0.5, -1,       1, 1,   // 右上               1, 0
            0.5, -0.5, -1,      1, 0,   // 右下               1, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, 0.5, -1,      0, 1,   // 左上               0, 0
            0.5, 0.5, -1,       1, 1    // 右上               1, 0
        ]
        
        guard let targetProgram = program1 else {
            return
        }
        
        glGenBuffers(1, &vbo1)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo1)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLfloat>.size, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_position")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
    }
    
    fileprivate func setupTexure() {
        textId = GLESUtils.createTexture2D(fileName: "dungeon_01.jpg")
    }
    
}
