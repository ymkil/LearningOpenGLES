//
//  AGLKView.swift
//  Tutorial-03-立方体
//
//  Created by mkil on 2019/4/23.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

let kLimitDegree:Float = 35

class AGLKView: UIView {
    
    var myContext:EAGLContext?
    var myColorFrameBuffer:GLuint = 0
    var myColorRenderBuffer:GLuint = 0
    var myDepthRenderBuffer:GLuint = 0
    var myVertices:GLuint = 0
    
    var positionSlot:GLuint = 0
    var colorSlot:GLuint = 0
    
    var projectionMatrixSlot:GLuint = 0
    var modelViewMatrixSlot:GLuint = 0
    var viewSlot:GLuint = 0
    
    var myProgram:GLuint?
    
    var degreeX:Float = 0
    var degreeY:Float = 0
    
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
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = (touches as NSSet).anyObject() as? UITouch {
            let currentPoint = touch.location(in: self)
            let previousPoint = touch.previousLocation(in: self)
            self.degreeY += Float(currentPoint.y - previousPoint.y)
            self.degreeX += Float(currentPoint.x - previousPoint.x)
            if self.degreeY > kLimitDegree {
                self.degreeY = kLimitDegree;
            }
            if self.degreeY < -kLimitDegree {
                self.degreeY = -kLimitDegree;
            }
            render()
        }
    }
    
    fileprivate func render() {
        glClearColor(0, 0, 0, 1.0)
        
        let scale = UIScreen.main.scale
        glViewport(GLint(frame.origin.x * scale), GLint(frame.origin.y * scale), GLsizei(self.frame.size.width * scale), GLsizei(self.frame.size.height * scale))
        
        let vertices: [GLfloat] = [
            // 前面
            -0.5, 0.5, 0.5,      0.0, 1.0, // 前左上 0
            -0.5, -0.5, 0.5,     0.0, 0.0, // 前左下 1
            0.5, -0.5, 0.5,      1.0, 0.0, // 前右下 2
            0.5, 0.5, 0.5,       1.0, 1.0, // 前右上 3
            // 后面
            -0.5, 0.5, -0.5,     1.0, 1.0, // 后左上 4
            -0.5, -0.5, -0.5,    1.0, 0.0, // 后左下 5
            0.5, -0.5, -0.5,     0.0, 0.0, // 后右下 6
            0.5, 0.5, -0.5,      0.0, 1.0, // 后右上 7
            // 左面
            -0.5, 0.5, -0.5,     0.0, 1.0, // 后左上 8
            -0.5, -0.5, -0.5,    0.0, 0.0, // 后左下 9
            -0.5, 0.5, 0.5,      1.0, 1.0, // 前左上 10
            -0.5, -0.5, 0.5,     1.0, 0.0, // 前左下 11
            // 右面
            0.5, 0.5, 0.5,       0.0, 1.0, // 前右上 12
            0.5, -0.5, 0.5,      0.0, 0.0, // 前右下 13
            0.5, -0.5, -0.5,     1.0, 0.0, // 后右下 14
            0.5, 0.5, -0.5,      1.0, 1.0, // 后右上 15
            // 上面
            -0.5, 0.5, 0.5,      0.0, 0.0, // 前左上 16
            0.5, 0.5, 0.5,       1.0, 0.0, // 前右上 17
            -0.5, 0.5, -0.5,     0.0, 1.0, // 后左上 18
            0.5, 0.5, -0.5,      1.0, 1.0, // 后右上 19
            // 下面
            -0.5, -0.5, 0.5,     0.0, 1.0, // 前左下 20
            0.5, -0.5, 0.5,      1.0, 1.0, // 前右下 21
            -0.5, -0.5, -0.5,    0.0, 0.0, // 后左下 22
            0.5, -0.5, -0.5,     1.0, 0.0, // 后右下 23
        ]
        
        
        // 索引
        let indices:[GLubyte] = [
            // 前面
            0, 1, 2,
            0, 2, 3,
            // 后面
            4, 5, 6,
            4, 6, 7,
            // 左面
            8, 9, 11,
            8, 11, 10,
            // 右面
            12, 13, 14,
            12, 14, 15,
            // 上面
            18, 16, 17,
            18, 17, 19,
            // 下面
            20, 22, 23,
            20, 23, 21
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
        
        let textCoord = glGetAttribLocation(self.myProgram!, "textCoordinate")
    
        glVertexAttribPointer(
            GLuint(textCoord),
            2,
            GLenum(GL_FLOAT),
            GLboolean(GL_FALSE),
            GLsizei(MemoryLayout<GLfloat>.size * 5), UnsafeRawPointer(bitPattern:3 * MemoryLayout<GLfloat>.size))
        glEnableVertexAttribArray(GLuint(textCoord))
        
        
        setupTexture(fileName: "dungeon_01.jpg")
        
        
        let width = frame.size.width
        let height = frame.size.height
        
        var projectionMatrix = Matrix.matrix4(0)
        Matrix.matrixLoadIdentity(resultM4: &projectionMatrix)
        let aspect = width / height
        
        //        我们设置视锥体的近裁剪面到观察者的距离为 0.1， 远裁剪面到观察者的距离为 100，视角为 35度，然后装载投影矩阵。默认的观察者位置在原点，视线朝向 -Z 方向，因此近裁剪面其实就在 z = -0.01 这地方，远裁剪面在 z = -100 这地方，z 值不在(-0.01, -100) 之间的物体是看不到的
        Matrix.perspective(resultM4: &projectionMatrix, 35, Float(aspect), 0.1, 100)  //透视变换，视角30°
        
        // 设置glsl投影矩阵
        glUniformMatrix4fv(GLint(projectionMatrixSlot), 1, GLboolean(GL_FALSE), projectionMatrix.array)
        
        var modelViewMatrix = Matrix.matrix4(0)
        Matrix.matrixLoadIdentity(resultM4: &modelViewMatrix)
        
        
        var viewMatrix = Matrix.matrix4(0)
        Matrix.matrixLoadIdentity(resultM4: &viewMatrix)
        var eyeVec3 = Vec3(x:0,y:0,z:3)
        var targetVec3 = Vec3(x:0,y:0,z:0)
        var upVec3 = Vec3(x:0,y:1,z:0)
        
        
        Matrix.lookAt(resultM4: &viewMatrix, eye: &eyeVec3, target: &targetVec3, up: &upVec3)
        glUniformMatrix4fv(GLint(viewSlot), 1, GLboolean(GL_FALSE), viewMatrix.array)
        
        // 平移
        // 设置 z 值 (-0.01,-100)之间
        Matrix.matrixTranslate(resultM4: &modelViewMatrix, tx: 0, ty: 0, tz: -3)
        
        var rotationMatrix = Matrix.matrix4(0)
        Matrix.matrixLoadIdentity(resultM4: &rotationMatrix)
        
        // 旋转
        Matrix.matrixRotate(resultM4: &rotationMatrix, angle: degreeY, x: 1, y: 0, z: 0)
        Matrix.matrixRotate(resultM4: &rotationMatrix, angle: degreeX, x: 0, y: 1, z: 0)
        
        var modelViewMatrixCopy = modelViewMatrix
        Matrix.matrixMultiply(resultM4: &modelViewMatrix, aM4: &rotationMatrix, bM4: &modelViewMatrixCopy)
        
        glUniformMatrix4fv(GLint(modelViewMatrixSlot), 1, GLboolean(GL_FALSE), modelViewMatrix.array)
        
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), indices)
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        
        glDeleteVertexArrays(1, &VAO)
        glDeleteBuffers(1, &VBO)
    }
}

extension AGLKView {
    
    fileprivate func setupLayer() {
        let eagLayer = layer as? CAEAGLLayer
        
        contentScaleFactor = UIScreen.main.scale
        
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
        // 开启深度缓存
        glEnable(GLenum(GL_DEPTH_TEST))
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
        myProgram = GLESUtils.loanProgram(verShaderFileName: "shaderv.glsl", fragShaderFileName: "shaderf.glsl")
        guard let myProgram = myProgram else {
            return
        }
        
        glUseProgram(myProgram)
        
        positionSlot = GLuint(glGetAttribLocation(myProgram, "position"))
        projectionMatrixSlot = GLuint(glGetUniformLocation(myProgram, "projectionMatrix"))
        modelViewMatrixSlot = GLuint(glGetUniformLocation(myProgram, "modelViewMatrix"))
        viewSlot = GLuint(glGetUniformLocation(myProgram, "viewMatrix"))
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

