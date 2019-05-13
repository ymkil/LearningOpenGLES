//
//  AGLKView.swift
//  Toturial-06-天空盒
//
//  Created by mkil on 2019/5/11.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import GLKit

class AGLKView: UIView {
    
    lazy var baseEffect: GLKBaseEffect = {
        return GLKBaseEffect()
    }()
    
    var myContext: EAGLContext?
    var myColorFrameBuffer: GLuint = 0
    var myColorRenderBuffer: GLuint = 0
    var myDepthRenderBuffer:GLuint = 0
    
    var sceneProgram: GLuint?
    
    var cubeVAOId: GLuint = 0
    var cubeVBOId: GLuint = 0
    
    var cubeTextId: GLuint = 0
    
    var skyboxEffect: SkyboxEffect?
    
    // 观察参数
    var eyePosition = GLKVector3Make(0, 10, 10)
    var targetPosition = GLKVector3Make(0, 0, 0)
    var upVector = GLKVector3Make(0, 1.0, 0)
    
    var myTimer:Timer?
    
    var angle: Float = 0.5
    
    // 只有CAEAGLLayer 类型的 layer 才支持 OpenGl 描绘
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        setupContext()
        setupProgram()
        setupVBOAndVAO()
        setupTexure()
        
        skyboxEffect = SkyboxEffect()
        skyboxEffect?.xSize = 6
        skyboxEffect?.ySize = 6
        skyboxEffect?.zSize = 6
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        EAGLContext.setCurrent(myContext)
        
        destoryRenderAndFrameBuffer()
        setupBuffer()
    
        startTimer()
    }
}


extension AGLKView {
    
    
    fileprivate func startTimer() {
        if myTimer == nil {
            myTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(onRes), userInfo: nil, repeats: true)
            myTimer?.fire()
        }
    }
    
    @objc func onRes() {
        
        angle += 0.01
        
        // 调整眼睛的位置
        eyePosition = GLKVector3Make(-5.0 * sinf(angle),
                                     -5.0,
                                     -5.0 * cosf(angle))
        // 调整观察的位置
        targetPosition = GLKVector3Make(0.0, 1.5 + -5.0 * sinf(0.3 * angle), 0.0)
        
        render()
    }
    
    fileprivate func render() {
        
        EAGLContext.setCurrent(myContext)
        
        guard let sceneProgram = sceneProgram else {
            return
        }
        
        glClearColor(0.18, 0.04, 0.14, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT) | UInt32(GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        let width = frame.size.width
        let height = frame.size.height
        
        baseEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), Float(width/height), 0.1, 20.0)
        
        baseEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(eyePosition.x,
                                                                    eyePosition.y,
                                                                    eyePosition.z,
                                                                    targetPosition.x,
                                                                    targetPosition.y, targetPosition.z,
                                                                    upVector.x,
                                                                    upVector.y,
                                                                    upVector.z)
        skyboxEffect?.center = eyePosition
        skyboxEffect?.transform.projectionMatrix = baseEffect.transform.projectionMatrix
        skyboxEffect?.transform.modelviewMatrix = baseEffect.transform.modelviewMatrix
        
        // 绘制天空盒
        skyboxEffect?.prepareToDraw()
        glDepthMask(GLboolean(GL_FALSE))
        glEnable(GLenum(GL_CULL_FACE))
        skyboxEffect?.draw()
        glDepthMask(GLboolean(GL_TRUE))

        // 绘制物体
        glUseProgram(sceneProgram)
        
        let modelViewProjection = GLKMatrix4Multiply(baseEffect.transform.projectionMatrix, baseEffect.transform.modelviewMatrix)
        
        glUniformMatrix4fv(glGetUniformLocation(sceneProgram, "u_mvpMatrix"), 1, GLboolean(GL_FALSE), modelViewProjection.array)
        
        glBindVertexArray(cubeVAOId)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), cubeTextId)
        glUniform1i(glGetUniformLocation(sceneProgram, "colorMap"), 0)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
        
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
        guard let sceneProgram = sceneProgram else{
            return
        }
        glUseProgram(sceneProgram)
    }
    
    fileprivate func setupVBOAndVAO() {
        
        // 指定立方体顶点属性数据 顶点位置 纹理
        let cubeVertices: [GLfloat] = [
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

        
        guard let sceneProgram = sceneProgram else {
            return
        }
        
        glGenVertexArrays(1, &cubeVAOId)
        glGenBuffers(1, &cubeVBOId)
        glBindVertexArray(cubeVAOId)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), cubeVBOId)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), cubeVertices.count * MemoryLayout<GLfloat>.size, cubeVertices, GLenum(GL_STATIC_DRAW))
        // 顶点位置数据
        glVertexAttribPointer(
            GLuint(glGetAttribLocation(sceneProgram, "position")),
            3,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(sceneProgram, "position")))
        // 顶点纹理数据
        glVertexAttribPointer(
            GLuint(glGetAttribLocation(sceneProgram, "textCoordinate")),
            2,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(sceneProgram, "textCoordinate")))
        glBindVertexArray(0)
        
    }
    
    fileprivate func setupTexure() {
        cubeTextId = GLESUtils.createTexture2D(fileName: "container.jpg")
    }
}
