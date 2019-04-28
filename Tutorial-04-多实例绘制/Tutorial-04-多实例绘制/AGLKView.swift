//
//  AGLKView.swift
//  Tutorial-04-多实例绘制
//
//  Created by mkil on 2019/4/28.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

class AGLKView: UIView {
    
    var myContext:EAGLContext?
    var myColorFrameBuffer:GLuint = 0
    var myColorRenderBuffer:GLuint = 0
    
    var myProgram:GLuint?
    
    var positionSlot:GLuint = 0
    var texcoordSlot:GLuint = 0
    var offsetSlot:GLuint = 0
    
    var vbo:GLuint = 0
    var offsetVBO:GLuint = 0
    
    var vertCount:Int = 0
    
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
        setupOffset()
        setupTexture(fileName: "dungeon_01.jpg")
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
        
        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        // 绘制
        glDrawArraysInstanced(GLenum(GL_TRIANGLES), 0, GLsizei(vertCount), 3)
        
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
}


extension AGLKView {
    fileprivate func setupVBO() {
        
        vertCount = 6
        
        let vertices: [GLfloat] = [
            -0.5,  1.0, 0.0, 1.0, 0.0,   // 右上
            -0.5,  0.5, 0.0, 1.0, 1.0,   // 右下
            -1.0,  0.5, 0.0, 0.0, 1.0,  // 左下
            -1.0,  0.5, 0.0, 0.0, 1.0,  // 左下
            -1.0,  1.0, 0.0, 0.0, 0.0,  // 左上
            -0.5,  1.0, 0.0, 1.0, 0.0,   // 右上
        ]
        
        vbo = GLESUtils.createVBO(GLenum(GL_ARRAY_BUFFER), Int(GL_STATIC_DRAW), MemoryLayout<GLfloat>.size * vertices.count, data: vertices)
        glEnableVertexAttribArray(positionSlot)
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        
        glEnableVertexAttribArray(texcoordSlot)
        glVertexAttribPointer(texcoordSlot, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
    }
    
    fileprivate func setupOffset()
    {
        guard let myProgram = myProgram else {
            return
        }
        
        let vertices: [GLfloat] = [
            0.1, -0.1, 0.0,
            0.7, -0.7, 0.0,
            1.3, -1.3, 0.0,
        ]
        
        offsetVBO = GLESUtils.createVBO(GLenum(GL_ARRAY_BUFFER), Int(GL_STATIC_DRAW), MemoryLayout<GLfloat>.size * vertices.count, data: vertices)
        glEnableVertexAttribArray(offsetSlot)
        glVertexAttribPointer(offsetSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, UnsafeRawPointer(bitPattern: 0))
        
        // 每次绘制之后，对offset进行1个偏移
        glVertexAttribDivisor(GLuint(glGetAttribLocation(myProgram, "offset")), 1);
        
    }
    
    fileprivate func setupTexture(fileName:String) {
        
        // 1获取图片的CGImageRef
        guard let spriteImage = UIImage(named: fileName)?.cgImage else {
            print("Failed to load image \(fileName)")
            return
        }
        
        // 读取图片大小
        let width = spriteImage.width
        let height = spriteImage.height
        
        let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
        
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        // 3在CGContextRef上绘图
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
        glBindTexture(GLenum(GL_TEXTURE_2D), 0);
        
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        let fw = width
        let fh = height;
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(fw), GLsizei(fh), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData);
        
        glBindTexture(GLenum(GL_TEXTURE_2D), 0);
        
        free(spriteData)
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
        
        positionSlot = GLuint(glGetAttribLocation(myProgram, "position"))
        texcoordSlot = GLuint(glGetAttribLocation(myProgram, "texcoord"))
        offsetSlot = GLuint(glGetAttribLocation(myProgram, "offset"))
    }
}

