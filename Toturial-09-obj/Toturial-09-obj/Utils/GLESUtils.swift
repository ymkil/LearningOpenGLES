//
//  GLESUtils.swift
//  OpenGL-ES-04
//
//  Created by mkil on 2019/1/10.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit
import OpenGLES

struct GLESUtils {
    
    static func loadShaderFile(type:GLenum, fileName:String) -> GLuint {
        guard let path = Bundle.main.path(forResource: fileName, ofType: nil) else {
            print("Error: file does not exist !")
            return 0;
        }
        
        do {
            let shaderString = try String(contentsOfFile: path, encoding: .utf8)
            return GLESUtils.loadShaderString(type: type, shaderString: shaderString)
        } catch {
            print("Error: loading shader file: \(path)")
            return 0;
        }
    }
    
    static func loadShaderString(type:GLenum, shaderString:String) ->GLuint {
        // 创建着色器对象
        let shaderHandle = glCreateShader(type)
        
        var shaderStringLength: GLint = GLint(Int32(shaderString.count))
        var shaderCString = NSString(string: shaderString).utf8String
        
        /* 把着色器源码附加到着色器对象上
         glShaderSource(shader: GLuint, count: GLsizei, String: UnsafePointer<UnsafePointer<GLchar>?>!, length: UnsafePointer<GLint>!)
         shader： 着色器对象
         count：指定要传递的源码字符串数量，这里只有一个
         String：着色器源码
         length：源码长度
         */
        glShaderSource(shaderHandle, GLsizei(1), &shaderCString, &shaderStringLength)
        
        // 编译着色器
        glCompileShader(shaderHandle)
        
        // 编译是否成功的状态 GL_FALSE GL_TRUE
        var compileStatus: GLint = 0
        // 获取编译状态
        glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileStatus)
        
        if compileStatus == GL_FALSE {
            var infoLength: GLsizei = 0
            let bufferLength: GLsizei = 1024
            glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &infoLength)
            
            let info: [GLchar] = Array(repeating: GLchar(0), count: Int(bufferLength))
            var actualLength: GLsizei = 0
            
            // 获取错误消息
            glGetShaderInfoLog(shaderHandle, bufferLength, &actualLength, UnsafeMutablePointer(mutating: info))
            NSLog(String(validatingUTF8: info)!)
            print("Error: Colourer Compilation Failure: \(String(validatingUTF8: info) ?? "")")
            return 0
        }
        
        return shaderHandle
    }
    
    static func loanProgram(verShaderFileName:String,fragShaderFileName:String) -> GLuint {
        
        let vertexShader = GLESUtils.loadShaderFile(type: GLenum(GL_VERTEX_SHADER), fileName: verShaderFileName)
        
        if vertexShader == 0 {return 0}
        
        let fragmentShader = GLESUtils.loadShaderFile(type: GLenum(GL_FRAGMENT_SHADER), fileName: fragShaderFileName)
        
        if fragmentShader == 0 {
            glDeleteShader(vertexShader)
            return 0
        }
        
        // 创建着色器程序对象
        let programHandel = glCreateProgram()
        
        if programHandel == 0 {return 0}
        
        // 将着色器附加到程序上
        glAttachShader(programHandel, vertexShader)
        glAttachShader(programHandel, fragmentShader)
        
        // 链接着色器程序
        glLinkProgram(programHandel)
        
        // 获取l链接状态
        var linkStatus: GLint = 0
        glGetProgramiv(programHandel, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE {
            var infoLength: GLsizei = 0
            let bufferLenght: GLsizei = 1024
            glGetProgramiv(programHandel, GLenum(GL_INFO_LOG_LENGTH), &infoLength)
            
            let info: [GLchar] = Array(repeating: GLchar(0), count: Int(bufferLenght))
            var actualLenght: GLsizei = 0
            
            // 获取错误消息
            glGetProgramInfoLog(programHandel, bufferLenght, &actualLenght, UnsafeMutablePointer(mutating: info))
            print("Error: Colorer Link Failed: \(String(validatingUTF8: info) ?? "")")
            return 0
        }
        
        // 释放资源
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
        
        return programHandel
    }
    
    static func createVBO(_ target:GLenum, _ usage: Int, _ datSize: Int, data:UnsafeRawPointer!) ->GLuint {
        var vbo:GLuint = 0
        glGenBuffers(1, &vbo)
        glBindBuffer(target, vbo)
        glBufferData(target, datSize, data, GLenum(usage))
        return vbo
    }
    
    static func createTexture2D(fileName: String) -> GLuint
    {
        // 1获取图片的CGImageRef
        guard let spriteImage = UIImage(named: fileName)?.cgImage else {
            print("Failed to load image \(fileName)")
            return 0
        }
        return GLESUtils.createTexture2DFactory(spriteImage)
    }
    
    static func createTexture2D(filePath: String) -> GLuint
    {
        // 1获取图片的CGImageRef
        guard let spriteImage = UIImage(contentsOfFile: filePath)?.cgImage else {
            print("Failed to load image \(filePath)")
            return 0
        }
        return GLESUtils.createTexture2DFactory(spriteImage)
    }
    
    fileprivate static func createTexture2DFactory(_ spriteImage: CGImage) -> GLuint {
        var texture: GLuint = 0
        
        // 读取图片大小
        let width = spriteImage.width
        let height = spriteImage.height
        
        let spriteData = calloc(width * height * 4, MemoryLayout<GLubyte>.size)
        
        let spriteContext = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        // 3在CGContextRef上绘图
        spriteContext?.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 4绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
        glGenTextures(1, &texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), texture);
        
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR );
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE);
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE);
        
        let fw = width
        let fh = height;
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(fw), GLsizei(fh), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), spriteData);
        
        glBindTexture(GLenum(GL_TEXTURE_2D), 0);
        
        free(spriteData)
        return texture
    }
}
