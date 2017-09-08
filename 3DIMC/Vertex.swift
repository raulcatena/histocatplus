//
//  Vertex.swift
//  TestMetal
//
//  Created by Raul Catena on 8/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

import Foundation

struct Vertex {
    var x, y, z : Float
    var r, g, b, a : Float
    
    func floatBuffer() -> [Float] {
        return[x, y, z, r, g, b, a]
    }
}

struct VertexNoColor {
    var x, y, z : Float
    
    func floatBuffer() -> [Float] {
        return[x, y, z]
    }
}
