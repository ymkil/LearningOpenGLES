//
//  AGLKView.swift
//  Toturial-09-obj
//
//  Created by mkil on 2019/6/18.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import GLKit

class AGLKView: UIView {
    
    var presentContex: EAGLContext?
    
    var frameBuffer: GLuint = 0     // 默认帧缓存
    var colorRenderBuffer: GLuint = 0
    var depthRenderBuffer: GLuint = 0
    
    var program: GLuint?
    
    var vbo: GLuint = 0
    
    var textId: GLuint = 0
    
    var loadObj: ObjLoader?
    
    var angle: Float = 0.5
    
    var myTimer:Timer?
    
    
    // 只有CAEAGLLayer 类型的 layer 才支持 OpenGl 描绘
    override class var layerClass : AnyClass {
        return CAEAGLLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadObject()
        setupLayer()
        setupContext()
        setupProgram()
        setupVBO()
        setupTexure()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    override func layoutSubviews() {
        EAGLContext.setCurrent(presentContex)
        
        destoryRenderAndFrameBuffer()
        setupBuffer()
        
//        render()
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
        
        angle += 0.03
        
        render()
    }
    
    fileprivate func render() {
        
        guard let program = program, let loadObj = loadObj else {
            return
        }
        
        
        glClearColor(1.0, 1.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        glEnable(GLenum(GL_DEPTH_TEST))   // 开启深度缓存
        
        let width = frame.size.width
        let height = frame.size.height
        
        let projectionMatrix = GLKMatrix4MakePerspective(
            GLKMathDegreesToRadians(85.0),
            GLfloat(width / height),
            1,
            150)
        
        var modelMatrix =  GLKMatrix4Rotate(GLKMatrix4MakeTranslation(0, 0, -15.5), GLKMathDegreesToRadians(20), 1, 0, 0)
        modelMatrix = GLKMatrix4RotateY(modelMatrix, angle)
        
        glUseProgram(program)
        let targetModelProjection = GLKMatrix4Multiply(projectionMatrix, modelMatrix)
        glUniformMatrix4fv(glGetUniformLocation(program, "u_modelMatrix"), 1, GLboolean(GL_FALSE), targetModelProjection.array)
        
        
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textId)
        glUniform1i(glGetUniformLocation(program,"u_Texture"), 0)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(loadObj.data.vertexIndexs.count))
        presentContex?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
}

extension AGLKView {
    
    // 加载obj
    fileprivate func loadObject() {
        
        let armoryHelper = ArmoryHelper()
        let source = try? armoryHelper.loadObjArmory("key")
        
        if let source = source {
            loadObj = ObjLoader(source: source, basePath: armoryHelper.resourcePath)
            do {
                try loadObj?.read()
            } catch {
                print("Parsing failed with unknown error")
            }
        }
    }
    
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
    
    fileprivate func setupProgram() {
        program = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
    }
    
    fileprivate func setupVBO() {
        
        guard let program = program, let loadObj = loadObj else {
            return
        }
        
        vbo = GLESUtils.createVBO(GLenum(GL_ARRAY_BUFFER), Int(GL_STATIC_DRAW), MemoryLayout<GLfloat>.size * loadObj.data.mergeVertices.count, data: loadObj.data.mergeVertices)

        glEnableVertexAttribArray(GLuint(glGetAttribLocation(program, "a_position")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(program, "a_position")), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(glGetAttribLocation(program, "a_TexCoord")))
        glVertexAttribPointer(GLuint(glGetAttribLocation(program, "a_TexCoord")), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 8), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
    }
    
    fileprivate func setupTexure() {
        textId = GLESUtils.createTexture2D(fileName: "key.bmp")
    }
    
}
