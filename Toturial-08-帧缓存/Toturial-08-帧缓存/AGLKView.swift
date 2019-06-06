//
//  AGLKView.swift
//  Toturial-08-帧缓存
//
//  Created by mkil on 2019/6/4.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import GLKit

class AGLKView: UIView {
    
    var presentContex: EAGLContext?
    
    var frameBuffer: GLuint = 0   // 默认帧缓存
    var colorRenderBuffer: GLuint = 0
    var depthRenderBuffer: GLuint = 0
    
    var frameBuffer1: GLuint = 0
    var frameBuffer1Size: CGSize = CGSize(width: 256, height: 256)
    
    var program: GLuint?
    var program1: GLuint?
    
    var vbo: GLuint = 0
    var vao: GLuint = 0
    
    var vbo1: GLuint = 0
    var vao1: GLuint = 0
    
    var textId: GLuint = 0
    var frameTextId: GLuint = 0
    
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
        setupBuffer1(frameBuffer1Size)
        
        render()
    }
    
    
}


extension AGLKView {
    
    fileprivate func render() {
        
        guard let program = program, let program1 = program1 else {
             return
        }
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))

        glEnable(GLenum(GL_DEPTH_TEST))   // 开启深度缓存
        glEnable(GLenum(GL_CULL_FACE))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
//
        let width = frame.size.width
        let height = frame.size.height

        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), Float(width/height), 1, 150.0)

        var modelMatrix =  GLKMatrix4Rotate(GLKMatrix4MakeTranslation(0, 0, -2.5), GLKMathDegreesToRadians(20), 1, 0, 0)
//
        glUseProgram(program)
        let targetModelProjection = GLKMatrix4Multiply(projectionMatrix, modelMatrix)
        glUniformMatrix4fv(glGetUniformLocation(program, "u_modelMatrix"), 1, GLboolean(GL_FALSE), targetModelProjection.array)

        glBindVertexArray(vbo)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
        glUniform1i(glGetUniformLocation(program,"u_Texture"), 0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
        
        glBindBuffer(GLenum(GL_FRAMEBUFFER), 0)

        /*----------*/
        
//        glUseProgram(program)
//        glBindBuffer(GLenum(GL_FRAMEBUFFER), frameBuffer1)
//        glClearColor(1.0, 1.0, 1.0, 1.0)
//        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
//        glViewport(0, 0, GLsizei(frameBuffer1Size.width), GLsizei(frameBuffer1Size.height))
//        glEnable(GLenum(GL_DEPTH_TEST))   // 开启深度缓存
//
//        glUniformMatrix4fv(glGetUniformLocation(program, "u_modelMatrix"), 1, GLboolean(GL_FALSE), targetModelProjection.array)
//
//        glBindVertexArray(vbo)
//        glActiveTexture(GLenum(GL_TEXTURE0))
//        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
//        glUniform1i(glGetUniformLocation(program,"u_Texture"), 0)
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
//
    
        glUseProgram(program1)
//        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)

//        glClearColor(0.0, 1.0, 1.0, 1.0)
//        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
//        glViewport(GLint(frame.size.width - frameBuffer1Size.width) , GLint(frame.size.height - frameBuffer1Size.height), GLsizei(frameBuffer1Size.width), GLsizei(frameBuffer1Size.height))
//        glEnable(GLenum(GL_DEPTH_TEST))   // 开启深度缓存

        modelMatrix = GLKMatrix4RotateY(modelMatrix, 100)
        let targetModelProjection1 = GLKMatrix4Multiply(projectionMatrix, modelMatrix)
        glUniformMatrix4fv(glGetUniformLocation(program1, "u_modelMatrix"), 1, GLboolean(GL_FALSE), targetModelProjection1.array)

        glBindVertexArray(vbo1)
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
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
        
        //        当 UIView 在进行布局变化之后，由于 layer 的宽高变化，导致原来创建的 renderbuffer不再相符，我们需要销毁既有 renderbuffer 和 framebuffer。下面，我们依然创建私有方法 destoryRenderAndFrameBuffer 来销毁生成的 buffer
        glDeleteFramebuffers(1, &frameBuffer)
        frameBuffer = 0
        glDeleteRenderbuffers(1, &colorRenderBuffer)
        colorRenderBuffer = 0
    }
    
    fileprivate func setupBuffer() {
        
        // 窗口默认帧缓存
        
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        // 为 color renderbuffer 分配存储空间
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
    
        
        // 将 colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), depthRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
    }
    
    fileprivate func setupBuffer1(_ framebufferSize:CGSize) {
        
        glGenFramebuffers(1, &frameBuffer1)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer1)
        
        // 生成颜色缓冲区的纹理对象并绑定到framebuffer上
        glGenTextures(1, &frameTextId)
        glBindTexture(GLenum(GL_TEXTURE_2D), frameTextId)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(framebufferSize.width), GLsizei(framebufferSize.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), nil)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), frameTextId, 0)
        
        // 生成深度缓冲区的纹理对象并绑定到framebuffer上
        
//        var framebufferDepthTexture: GLuint = 0
//        glGenTextures(1, &framebufferDepthTexture)
//        glBindTexture(GLenum(GL_TEXTURE_2D), framebufferDepthTexture)
//        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_DEPTH_COMPONENT, GLsizei(framebufferSize.width), GLsizei(framebufferSize.height), 0, GLenum(GL_DEPTH_COMPONENT), GLenum(GL_UNSIGNED_BYTE), nil)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
//        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
//
//        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_TEXTURE_2D), framebufferDepthTexture, 0)
        
        let status = glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER))
        
        if status == GL_FRAMEBUFFER_COMPLETE {
            print("fbo complete width \(framebufferSize.width) height \(framebufferSize.height)")
        } else if status == GL_FRAMEBUFFER_UNSUPPORTED {
            print("fbo unsupported")
        } else {
            print("Framebuffer Error")
        }
        
    
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
    }
    
    fileprivate func setupProgram() {
        program = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
        program1 = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
    }
    
    fileprivate func setupVBO() {
        // 指定立方体顶点属性数据 顶点位置 纹理
        let vertices: [GLfloat] = [
            -0.5, -0.5, 0.5, 0.0, 0.0,    // A
            0.5, -0.5, 0.5, 1.0, 0.0,    // B
            0.5, 0.5, 0.5,1.0, 1.0,    // C
            0.5, 0.5, 0.5,1.0, 1.0,    // C
            -0.5, 0.5, 0.5,0.0, 1.0,    // D
            -0.5, -0.5, 0.5,0.0, 0.0,    // A
            
            
            -0.5, -0.5, -0.5,0.0, 0.0,    // E
            -0.5, 0.5, -0.5,0.0, 1.0,   // H
            0.5, 0.5, -0.5,1.0, 1.0,    // G
            0.5, 0.5, -0.5,1.0, 1.0,    // G
            0.5, -0.5, -0.5,1.0, 0.0,    // F
            -0.5, -0.5, -0.5,0.0, 0.0,    // E
            
            -0.5, 0.5, 0.5,0.0, 1.0,    // D
            -0.5, 0.5, -0.5,1.0, 1.0,   // H
            -0.5, -0.5, -0.5,1.0, 0.0,    // E
            -0.5, -0.5, -0.5,1.0, 0.0,    // E
            -0.5, -0.5, 0.5,0.0, 0.0,    // A
            -0.5, 0.5, 0.5,0.0, 1.0,    // D
            
            0.5, -0.5, -0.5,1.0, 0.0,    // F
            0.5, 0.5, -0.5,1.0, 1.0,    // G
            0.5, 0.5, 0.5,0.0, 1.0,    // C
            0.5, 0.5, 0.5,0.0, 1.0,    // C
            0.5, -0.5, 0.5, 0.0, 0.0,    // B
            0.5, -0.5, -0.5,1.0, 0.0,    // F
            
            0.5, 0.5, -0.5,1.0, 1.0,    // G
            -0.5, 0.5, -0.5,0.0, 1.0,   // H
            -0.5, 0.5, 0.5,0.0, 0.0,    // D
            -0.5, 0.5, 0.5,0.0, 0.0,    // D
            0.5, 0.5, 0.5,1.0, 0.0,    // C
            0.5, 0.5, -0.5,1.0, 1.0,    // G
            
            -0.5, -0.5, 0.5,0.0, 0.0,    // A
            -0.5, -0.5, -0.5, 0.0, 1.0,// E
            0.5, -0.5, -0.5,1.0, 1.0,    // F
            0.5, -0.5, -0.5,1.0, 1.0,    // F
            0.5, -0.5, 0.5,1.0, 0.0,    // B
            -0.5, -0.5, 0.5,0.0, 0.0,    // A
        ]
        
        guard let targetProgram = program else {
            return
        }
        
        glGenVertexArrays(1, &vao)
        glGenBuffers(1, &vbo)
        glBindVertexArray(vao)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLfloat>.size, vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_position")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
    }
    
    
    fileprivate func setupVBO1() {
        let vertices: [GLfloat] = [
            -0.5, -0.5, 0.5, 0.0, 0.0,    // A
            0.5, -0.5, 0.5, 1.0, 0.0,    // B
            0.5, 0.5, 0.5,1.0, 1.0,    // C
            0.5, 0.5, 0.5,1.0, 1.0,    // C
            -0.5, 0.5, 0.5,0.0, 1.0,    // D
            -0.5, -0.5, 0.5,0.0, 0.0,    // A
        ]
        
        guard let targetProgram = program1 else {
            return
        }
        
        glGenVertexArrays(1, &vao1)
        glGenBuffers(1, &vbo1)
        glBindVertexArray(vao1)
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
