//
//  Cube.swift
//  TestMetal
//
//  Created by Raul Catena on 8/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

import Foundation
import Metal

class Cube: Node {
    
    init(device: MTLDevice){
        
        let A = VertexNoColor(x: -0.3, y:   0.3, z:   0.3)
        let B = VertexNoColor(x: -0.3, y:  -0.3, z:   0.3)
        let C = VertexNoColor(x:  0.3, y:  -0.3, z:   0.3)
        let D = VertexNoColor(x:  0.3, y:   0.3, z:   0.3)
        
        let Q = VertexNoColor(x: -0.3, y:   0.3, z:  -0.3)
        let R = VertexNoColor(x:  0.3, y:   0.3, z:  -0.3)
        let S = VertexNoColor(x: -0.3, y:  -0.3, z:  -0.3)
        let T = VertexNoColor(x:  0.3, y:  -0.3, z:  -0.3)
        
        let verticesArray:Array<VertexNoColor> = [
            A,B,C ,A,C,D,   //Front
            R,T,S ,Q,R,S,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C    //Bot
        ]
        
        super.init(name: "Cube", verticesNoColor: verticesArray, device: device)
    }
    
    override func updateWithDelta(delta: CFTimeInterval) {
        
        super.updateWithDelta(delta: delta)
        
        let secsPerMove: Float = 6.0
        rotationY = sinf( Float(time) * 2.0 * .pi / secsPerMove)
        rotationX = sinf( Float(time) * 2.0 * .pi / secsPerMove)
    }
}
