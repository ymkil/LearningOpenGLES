//
//  AGLKView.swift
//  Tutorial-05-多重纹理
//
//  Created by mkil on 2019/5/6.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

class AGLKView: UIView {
    
    var myContext: EAGLContext?
    var myColorFrameBuffer: GLuint = 0
    var myColorRenderBuffer: GLuint = 0

    var myProgram: GLuint?
    
    var vbo: GLuint = 0
    
    var vertCount:Int = 0
    
    var position_loc: GLuint = 0
    var texture_loc: GLuint = 0
    
    var tex1_loc: Int32 = 0
    
    var tex1: GLuint = 0
    var tex2: GLuint = 0
    
    
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
        setupTexure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        EAGLContext.setCurrent(myContext)
        
        destoryRenderAndFrameBuffer()
        setupBuffer()
        
        render()
    }

}

extension AGLKView {
    fileprivate func render() {
        glClearColor(0.0, 1.0, 0.0, 1.0)
  
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        // 关闭第一个纹理混合
        glDisable(GLenum(GL_BLEND))
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), tex1)
        glUniform1i(tex1_loc, 0)
        
        // 绘制第一个纹理
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(vertCount));
        
        
        // 开启第二个纹理混合
        glEnable(GLenum(GL_BLEND));
        // 设置混合因子
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE));
        
        glActiveTexture(GLenum(GL_TEXTURE1))
        glBindTexture(GLenum(GL_TEXTURE_2D), tex2)
        glUniform1i(tex1_loc, 1)
        
        // 绘制第二个纹理
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(vertCount));
        
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
        
        position_loc = GLuint(glGetAttribLocation(myProgram, "in_position"))
        texture_loc = GLuint(glGetAttribLocation(myProgram, "in_tex_coord"))
        
        tex1_loc = glGetUniformLocation(myProgram, "tex1")
    
    }
    
    fileprivate func setupVBO() {

        let vertices: [GLfloat] = [
            0.5,  0.5, 1.0, 0.0,   // 右上
            0.5, -0.5, 1.0, 1.0,   // 右下
            -0.5, -0.5, 0.0, 1.0,  // 左下
            -0.5, -0.5, 0.0, 1.0,  // 左下
            -0.5,  0.5, 0.0, 0.0,  // 左上
            0.5,  0.5, 1.0, 0.0,   // 右上
        ]
        
        vertCount = vertices.count
                
        vbo = GLESUtils.createVBO(GLenum(GL_ARRAY_BUFFER), Int(GL_STATIC_DRAW), MemoryLayout<GLfloat>.size * vertices.count, data: vertices)
        glEnableVertexAttribArray(position_loc)
        glVertexAttribPointer(position_loc, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(texture_loc)
                glVertexAttribPointer(texture_loc, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 4), UnsafeRawPointer(bitPattern: 2 * MemoryLayout<GLfloat>.size))
    }
    
    
    fileprivate func setupTexure() {
        tex1 = GLESUtils.createTexture2D(fileName: "mixture.jpg")
        tex2 = GLESUtils.createTexture2D(fileName: "text.jpg")
    }
}

