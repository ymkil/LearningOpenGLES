//
//  AGLKView.swift
//  Toturial-07-漫反射光照
//
//  Created by mkil on 2019/5/16.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import GLKit

class AGLKView: UIView {
    
    var myContext: EAGLContext?
    var myColorFrameBuffer: GLuint = 0
    var myColorRenderBuffer: GLuint = 0
    var myDepthRenderBuffer:GLuint = 0
    
    var targetProgram: GLuint?
    
    var vbo: GLuint = 0
    
    var textId: GLuint = 0
    
    var myTimer:Timer?
    
    var angle: Float = 0.5
    
    var indexList: [GLubyte]?
    
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
        
        //        render()
        startTimer()
    }
    
}

// MARK: - 绘制
extension AGLKView {
    
    
    fileprivate func startTimer() {
        if myTimer == nil {
            myTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(onRes), userInfo: nil, repeats: true)
            myTimer?.fire()
        }
    }
    
    @objc func onRes() {
        
        angle += 0.03
        
        render()
    }
    
    fileprivate func render() {
        
        guard let targetProgram = targetProgram, let indexList = indexList else {
            return
        }
        
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        glEnable(GLenum(GL_DEPTH_TEST))   // 开启深度缓存
        glEnable(GLenum(GL_CULL_FACE))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        let width = frame.size.width
        let height = frame.size.height
        
        let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), Float(width/height), 1, 150.0)
        
        var modelMatrix =  GLKMatrix4Rotate(GLKMatrix4MakeTranslation(0, 0, -5), GLKMathDegreesToRadians(20), 1, 0, 0)
        modelMatrix = GLKMatrix4RotateY(modelMatrix, angle)
        glUseProgram(targetProgram)
        
        let targetModelProjection = GLKMatrix4Multiply(projectionMatrix, modelMatrix)
        glUniformMatrix4fv(glGetUniformLocation(targetProgram, "u_modelMatrix"), 1, GLboolean(GL_FALSE), targetModelProjection.array)
        
        
        // 设置光源
        glUniform3f(glGetUniformLocation(targetProgram, "u_Light.Color"), 1, 1, 1)
        glUniform1f(glGetUniformLocation(targetProgram, "u_Light.AmbientIntensity"), 0.6)
        glUniform3f(glGetUniformLocation(targetProgram, "u_Light.LightPos"), 0, 1, -1)
        glUniform1f(glGetUniformLocation(targetProgram, "u_Light.DiffuseIntensity"), 0.7)
        
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
        glUniform1i(glGetUniformLocation(targetProgram,"u_Texture"), 0)
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indexList.count), GLenum(GL_UNSIGNED_BYTE), indexList)
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
}

// MARK: - 环境设置
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
        targetProgram = GLESUtils.loanProgram(verShaderFileName: "shadeVertex.glsl", fragShaderFileName: "shadeFragment.glsl")
    }
    
    fileprivate func setupVBO() {
        
        // 指定立方体顶点属性数据 顶点位置 纹理 法向量
        let vertices: [GLfloat] = [
            
            1, -1, 1,   1, 0,  0, 0, 1,
            1,  1, 1,   1, 1,  0, 0, 1,
            -1,  1, 1,    0, 1,  0, 0, 1,
            -1, -1, 1,    0, 0,  0, 0, 1,
            
            -1, -1, -1,   1, 0,  0, 0,-1,
            -1,  1, -1,   1, 1,  0, 0,-1,
            1,  1, -1,   0, 1,  0, 0,-1,
            1, -1, -1,   0, 0,  0, 0,-1,
            
            -1, -1,  1,   1, 0, -1, 0, 0,
            -1,  1,  1,   1, 1, -1, 0, 0,
            -1,  1, -1,   0, 1, -1, 0, 0,
            -1, -1, -1,   0, 0, -1, 0, 0,
            
            1, -1, -1,   1, 0,  1, 0, 0,
            1,  1, -1,   1, 1,  1, 0, 0,
            1,  1,  1,   0, 1,  1, 0, 0,
            1, -1,  1,   0, 0,  1, 0, 0,
            
            1,  1,  1,   1, 0,  0, 1, 0,
            1,  1, -1,   1, 1,  0, 1, 0,
            -1,  1, -1,   0, 1,  0, 1, 0,
            -1,  1,  1,   0, 0,  0, 1, 0,
            
            1, -1, -1,   1, 0,  0,-1, 0,
            1, -1,  1,   1, 1,  0,-1, 0,
            -1, -1,  1,   0, 1,  0,-1, 0,
            -1, -1, -1,   0, 0,  0,-1, 0
            
        ]
        
        indexList = [
            // 前面
            0, 1, 2,
            2, 3, 0,
            
            // 背面
            4, 5, 6,
            6, 7, 4,
            
            // 左边
            8, 9, 10,
            10, 11, 8,
            
            // 右边
            12, 13, 14,
            14, 15, 12,
            
            // 顶部
            16, 17, 18,
            18, 19, 16,
            
            // 底部
            20, 21, 22,
            22, 23, 20
        ]
        
        guard let targetProgram = targetProgram else {
            return
        }
        
        vbo = GLESUtils.createVBO(GLenum(GL_ARRAY_BUFFER), Int(GL_STATIC_DRAW), MemoryLayout<GLfloat>.size * vertices.count, data: vertices)
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_Position")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_Position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_TexCoord")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(targetProgram, "a_Normal")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(targetProgram, "a_Normal")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern:5 * MemoryLayout<GLfloat>.size))
    }
    
    fileprivate func setupTexure() {
        textId = GLESUtils.createTexture2D(fileName: "dungeon_01.png")
    }
}
