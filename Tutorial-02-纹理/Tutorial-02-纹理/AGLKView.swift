//
//  AGLKView.swift
//  Tutorial-02-纹理
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
    var textCoordSlot:GLuint = 0
    
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
        
        glClearColor(1.0, 1.0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        glViewport(0, 0, GLsizei(frame.size.width), GLsizei(frame.size.height))
        
        // 注:纹理上下颠倒,这是因为OpenGL要求y轴0.0坐标是在图片的底部的，但是图片的y轴0.0坐标通常在顶部。
        // 解决1:glsl 里面 反转 y 轴(gl_Position = vec4(vPosition.x,-vPosition.y,vPosition.z,1.0))
        // 解决2:纹理坐标(s,t) -> (s,abs(t - 1))
        let vertices: [GLfloat] = [
            0.5, 0.5, -1,       1, 1,   // 右上               1, 0
            0.5, -0.5, -1,      1, 0,   // 右下               1, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, -0.5, -1,     0, 0,   // 左下               0, 1
            -0.5, 0.5, -1,      0, 1,   // 左上               0, 0
            0.5, 0.5, -1,       1, 1    // 右上               1, 0
        ]
        
        
        var VAO:GLuint = 0
        var VBO:GLuint = 0
        glGenVertexArrays(1, &VAO)
        glGenBuffers(GLsizei(1), &VBO)
        
        glBindVertexArray(VAO)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), VBO)
        let count = vertices.count
        let size =  MemoryLayout<GLfloat>.size
        glBufferData(GLenum(GL_ARRAY_BUFFER), count * size, vertices, GLenum(GL_STATIC_DRAW))
        
        
        glVertexAttribPointer(
            positionSlot,
            3,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern: 0))
        glEnableVertexAttribArray(positionSlot)
        
        glVertexAttribPointer(
            GLuint(textCoordSlot),
            2,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
        glEnableVertexAttribArray(GLuint(textCoordSlot))
        
        
        setupTexture(fileName: "dungeon_01.jpg")
        
        // 绘制
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        glDeleteVertexArrays(1, &VAO)
        glDeleteBuffers(1, &VBO)
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
        textCoordSlot = GLuint(glGetAttribLocation(myProgram, "textCoordinate"))
    }
    
    fileprivate func setupTexture(fileName:String) {
        
        // 获取图片的CGImageRef
        guard let spriteImage = UIImage(named: fileName)?.cgImage else {
            print("Failed to load image \(fileName)")
            return
        }
        
        // 读取图片大小
        let width = spriteImage.width
        let height = spriteImage.height
        
        let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
        
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        // 在CGContextRef上绘图
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
        glBindTexture(GLenum(GL_TEXTURE_2D), 0);
        
        // 为当前绑定的纹理对象设置环绕、过滤方式
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        // 加载并生成纹理
        let fw = width
        let fh = height;
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(fw), GLsizei(fh), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData);
        
        // 释放资源
        free(spriteData)
    }
    
    
}
