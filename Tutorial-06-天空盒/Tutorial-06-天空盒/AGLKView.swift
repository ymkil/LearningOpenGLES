//
//  AGLKView.swift
//  Tutorial-06-天空盒
//
//  Created by mkil on 2019/5/9.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

class AGLKView: UIView {

    var myContext: EAGLContext?
    var myColorFrameBuffer: GLuint = 0
    var myColorRenderBuffer: GLuint = 0
    var myDepthRenderBuffer:GLuint = 0
    
    var sceneProgram: GLuint?
    var skyBoxProgram: GLuint?
    
    var cubeVAOId: GLuint = 0
    var cubeVBOId: GLuint = 0
    
    var skyBoxVAOId: GLuint = 0
    var skyBoxVBOId: GLuint = 0
    
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
        
        var width:GLint = 0
        var height:GLint = 0
        
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &width)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &height)
        
        // 创建深度缓冲区
        var depthRenderBuffer:GLuint = 0
        glGenRenderbuffers(1, &depthRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), depthRenderBuffer)
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), width, height)
        myDepthRenderBuffer = depthRenderBuffer
        
        
        glGenFramebuffers(1, &buffer)
        myColorFrameBuffer = buffer
        // 设置为当前 framebuffer
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        
        
        // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT),
                                  GLenum(GL_RENDERBUFFER), myDepthRenderBuffer)
        
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        
    }
    
    
    fileprivate func setupProgram() {
        sceneProgram = GLESUtils.loanProgram(verShaderFileName: "cubev.glsl", fragShaderFileName: "cubef.glsl")
        skyBoxProgram = GLESUtils.loanProgram(verShaderFileName: "skyboxv.glsl", fragShaderFileName: "skyboxf.glsl")
        guard let sceneProgram = sceneProgram, let skyBoxProgram = skyBoxProgram else {
            return
        }
        glUseProgram(sceneProgram)
        glUseProgram(skyBoxProgram)
    }
    
    fileprivate func setupVBO() {
        
    }
}
