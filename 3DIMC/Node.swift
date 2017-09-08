//
//  Node.swift
//  TestMetal
//
//  Created by Raul Catena on 8/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node {
    var device : MTLDevice
    var name: String
    var vertexCount: Int
    var vertexBuffer: MTLBuffer
    
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    var positionZ: Float = 0.0
    
    var rotationX: Float = 0.0
    var rotationY: Float = 0.0
    var rotationZ: Float = 0.0
    var scale: Float     = 1.0
    
    var time:CFTimeInterval = 0.0
    
    init(name: String, vertices: [Vertex], device: MTLDevice) {
        self.device = device
        
        /*
            var vertexData = Array<Float>()
            for vertex in vertices{
                vertexData += vertex.floatBuffer()
            }
        */
 
        let lengthBuffer = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        vertexBuffer = device.makeBuffer(bytes: vertices, length: lengthBuffer, options: [])
        
        self.name = name
        vertexCount = vertices.count
    }
    
    init(name: String, verticesNoColor: [VertexNoColor], device: MTLDevice) {
        self.device = device
        
        /*
         var vertexData = Array<Float>()
         for vertex in vertices{
         vertexData += vertex.floatBuffer()
         }
         */
        
        let lengthBuffer = verticesNoColor.count * MemoryLayout.size(ofValue: verticesNoColor[0])
        vertexBuffer = device.makeBuffer(bytes: verticesNoColor, length: lengthBuffer, options: [])
        
        self.name = name
        vertexCount = verticesNoColor.count
    }
    
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, drawable: CAMetalDrawable, clearColor: MTLClearColor?){
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        renderEncoder.setCullMode(MTLCullMode.front)
        
        let nodeModelMatrix = self.modelMatrix()
        nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
        
        let uniformBuffer = device.makeBuffer(length: MemoryLayout<Float>.size * Matrix4.numberOfElements() * 2, options: [])
        let bufferPointer = uniformBuffer.contents()
        memcpy(bufferPointer, nodeModelMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,
                                     instanceCount: vertexCount/3)
        
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func modelMatrix()->Matrix4{
        let matrix = Matrix4()
        matrix.translate(positionX, y: positionY, z: positionZ)
        matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
        matrix.scale(scale, y: scale, z: scale)
        return matrix
    }
    
    func updateWithDelta(delta: CFTimeInterval){
        time += delta
    }
}
