//
//  AGLKView.swift
//  Tutorial-01-三角形
//
//  Created by mkil on 2019/1/24.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

class AGLKView: UIView {
    
    var myContext:EAGLContext?
    var myColorFrameBuffer:GLuint = 0
    var myColorRenderBuffer:GLuint = 0
    
    var myProgram:GLuint?
    
    var positionSlot:GLuint = 0
    var colorSlot:GLuint = 0
    
    // 只有CAEAGLLayer 类型的 layer 才支持 OpenGl 描绘
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    
    override func layoutSubviews() {
        setupLayer()
        setupContext()
        destoryRenderAndFrameBuffer()
        setupBuffer()
        setupProgram()
        
        render()
    }
}

extension AGLKView {
    
    fileprivate func render() {
        
        glClearColor(0, 1.0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        let vertices: [GLfloat] = [
            0, 0.5, 0,
            -0.5, -0.5, 0,
            0.5, -0.5, 0
        ]
        
        let colors: [GLfloat] = [
            1, 0, 0, 1,
            0, 1, 0, 1,
            0, 0, 1, 1
        ]
        
        // 加载顶点数据
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, vertices )
        glEnableVertexAttribArray(positionSlot)
        
        // 加载颜色数据
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, colors )
        glEnableVertexAttribArray(colorSlot)
        
        // 绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
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
        myContext = EAGLContext(api: .openGLES3)
        
        if myContext == nil {
            print("Failed to initialize OpenGLES 3.0 context")
            return
        }
        // 设置为当前上下文
        if !EAGLContext.setCurrent(myContext) {
            print("Failed to set current OpenGL context")
            return
        }
    }
    
    fileprivate func destoryRenderAndFrameBuffer() {
        //        当 UIView 在进行布局变化之后，由于 layer 的宽高变化，导致原来创建的 renderbuffer不再相符，我们需要销毁既有 renderbuffer 和 framebuffer。下面，我们依然创建私有方法 destoryRenderAndFrameBuffer 来销毁生成的 buffer
        glDeleteFramebuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
        glDeleteRenderbuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
    }
    
    fileprivate func setupBuffer() {
        var buffer:GLuint = 0
        glGenRenderbuffers(1, &buffer)
        myColorRenderBuffer = buffer
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        // 为 颜色缓冲区 分配存储空间
        myContext?.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer as? CAEAGLLayer)
        
        glGenFramebuffers(1, &buffer)
        myColorFrameBuffer = buffer
        // 设置为当前 framebuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
    }
    
    fileprivate func setupProgram() {
        myProgram = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
        guard let myProgram = myProgram else {
            return
        }
        
        glUseProgram(myProgram)
    
        positionSlot = GLuint(glGetAttribLocation(myProgram, "vPosition"))
        colorSlot = GLuint(glGetAttribLocation(myProgram, "a_Color"))
    }
}
