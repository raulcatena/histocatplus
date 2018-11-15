//
//  IMCMetalPolygonizedFieldRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 11/11/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import "IMCMetalPolygonizedFieldRenderer.h"

@interface IMCMetalPolygonizedFieldRenderer()
@property (nonatomic, strong) id<MTLBuffer> indexBuffer;
@property (nonatomic, strong) id<MTLBuffer> centroidsBuffer;
@property (nonatomic, strong) id<MTLBuffer> normalsBuffer;
@end

@implementation IMCMetalPolygonizedFieldRenderer

@synthesize cellsToRender = _cellsToRender;

-(void)updateColorBuffer{
    
    float ** data = [self.computation computedData];
    if(data && self.computation.verts){
        AlphaMode alphaMode = [self.delegate alphaMode];
        int stride = 4;

        NSInteger segments = self.computation.segmentedUnits;
        NSInteger bufferSize = segments * stride;
        float * buff = calloc(bufferSize, sizeof(float));
        float * buffCentroids = calloc(segments * 3, sizeof(float));
        if(buff){
            self.colorsObtained = [self.delegate colors];
            float minThresholdForAlpha = [self.delegate combinedAlpha];

            float * colors = (float *)malloc(self.colorsObtained.count * 3 * sizeof(float));

            for (int i = 0; i< self.colorsObtained.count; i++) {
                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
                colors[i * 3] = colorObj.redComponent/255.0f;
                colors[i * 3 + 1] = colorObj.greenComponent/255.0f;
                colors[i * 3 + 2] = colorObj.blueComponent/255.0f;
            }
            
            float * xCentroids = [self.computation xCentroids];
            float * yCentroids = [self.computation yCentroids];
            float * zCentroids = [self.computation zCentroids];

            NSInteger channels = self.indexesObtained.count;

            float maxes[channels];
            for (NSInteger idx = 0; idx < channels; idx++)
                maxes[idx] = [self.computation maxChannel:[self.indexesObtained[idx]integerValue]];

            for (NSInteger i = 0; i < segments; i++) {
                NSInteger internalCursor = i * stride;
                NSInteger internalCursorCentroids = i * 3;
                for (NSInteger idx = 0; idx < channels; idx++) {
                    NSInteger realIndex = [self.indexesObtained[idx]integerValue];

                    UInt8 val = (UInt8)((data[realIndex][i]/maxes[idx]) * 255.0f);
                    if(self.colorsObtained.count > 0){
                        buff[internalCursor] += val * colors[idx * 3];
                        buff[internalCursor + 1] += val * colors[idx * 3 + 1];
                        buff[internalCursor + 2] += val * colors[idx * 3 + 2];
                    }else{
                        RgbColor rgb = RgbFromFloatUnit(val/255.0f);
                        buff[internalCursor] += rgb.r/255.0f;
                        buff[internalCursor + 1] += rgb.g/255.0f;
                        buff[internalCursor + 2] += rgb.b/255.0f;
                    }
                    buffCentroids[internalCursorCentroids] = xCentroids[i];
                    buffCentroids[internalCursorCentroids + 1] = yCentroids[i];
                    buffCentroids[internalCursorCentroids + 2] = zCentroids[i];

                    //Filters
                    float max = .0f;
                    float sum = .0f;
                    for (int j = 0; j < 3; j++){
                        float val = buff[internalCursor + j];
                        if(val > max)
                            max = val;
                        sum += val;
                        if(sum > 1.0f){
                            sum = 1.0f;
                            break;
                        }
                    }

                    if(alphaMode == ALPHA_MODE_OPAQUE)
                        buff[internalCursor + 3] = max < minThresholdForAlpha ? 0.0f : 1.0f;
                    if(alphaMode == ALPHA_MODE_FIXED)
                        buff[internalCursor + 3] = max < minThresholdForAlpha ? 0.0f : minThresholdForAlpha;//Alpha
                    if(alphaMode == ALPHA_MODE_ADAPTIVE)
                        buff[internalCursor + 3] = max < minThresholdForAlpha ? 0.0f : sum;//MIN(1.0f, sum);//Alpha
                }
            }
            
            self.colorBuffer = [self.device newBufferWithBytes:buff length:bufferSize * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            self.centroidsBuffer = [self.device newBufferWithBytes:buffCentroids length:segments * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];

            free(buff);
            free(colors);
        }
        NSInteger cursor = 0;
        unsigned * cellIds = (unsigned *)calloc(self.computation.numberOfTriangles, sizeof(unsigned));
        unsigned * copyPtr = self.computation.cellTriangleOffsets;
        for(unsigned i  = 0; i < segments; i++){
            NSInteger to = copyPtr[i];
            for(; cursor < to; ++cursor)
                cellIds[cursor] = i;
        }
        NSLog(@"Cursor to %li expected: %u", cursor, self.computation.numberOfTriangles);
        self.maskBuffer = [self.device newBufferWithBytes:cellIds length:self.computation.numberOfTriangles * sizeof(unsigned) options:MTLResourceOptionCPUCacheModeDefault];
        self.vertexBuffer = [self.device newBufferWithBytes:self.computation.verts length:self.computation.numberOfTriangleVertices * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        self.normalsBuffer = [self.device newBufferWithBytes:self.computation.normals length:self.computation.numberOfTriangleVertices * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
        self.indexBuffer = [self.device newBufferWithBytes:self.computation.indexes length:self.computation.numberOfTriangles * 3 * sizeof(unsigned) options:MTLResourceOptionCPUCacheModeDefault];
        free(cellIds);
    }
}


-(void)drawInMTKView:(IMCMtkView *)view{
    view.framebufferOnly = NO;
    if(view.refresh == NO && !self.forceColorBufferRecalculation)
        return;
    if(!self.computation || !self.computation.isLoaded || !self.computation.computedData)
        return;
    
    view.refresh = NO;
    
    if(!self.device){
        self.device = view.device;
        [self createMetalStack];
    }
    //Projection Matrix
    [self projectionMatrixSetup:view];
    
    //Uniforms
    Constants uniforms;
    
    uniforms.modelViewMatrix = view.rotationMatrix->glkMatrix;
    uniforms.baseModelMatrix = view.baseModelMatrix->glkMatrix;
    uniforms.projectionMatrix = projectionMatrix->glkMatrix;
    GLKMatrix4 premultiplied = GLKMatrix4Multiply(uniforms.baseModelMatrix, uniforms.modelViewMatrix);
    GLKMatrix3 rFromMV = GLKMatrix4GetMatrix3(premultiplied);
    uniforms.premultipliedMatrix = GLKMatrix4Multiply(uniforms.projectionMatrix, premultiplied);
    bool isInvertible;
    uniforms.normalMatrix = GLKMatrix3Transpose(GLKMatrix3Invert(rFromMV, &isInvertible));
    
    self.uniformsBuffer = [self.device newBufferWithBytes:&uniforms length:sizeof(uniforms) options:MTLResourceOptionCPUCacheModeDefault];
    
    //Size model
    NSInteger width = [self.delegate witdhModel];
    NSInteger height = [self.delegate heightModel];
    
    
    //prepareData
    if([self checkNeedsUpdate] || self.forceColorBufferRecalculation)
        [self updateColorBuffer];
    self.forceColorBufferRecalculation = NO;
    
//    if(!self.colorBuffer)
//        return;
    
    //Positional Data
    PositionalData positional;
    positional.lowerY = view.lowerYOffset * height;
    positional.upperY = view.upperYOffset * height;
    positional.leftX = view.leftXOffset * width;
    positional.rightX = view.rightXOffset * width;
    positional.widthModel = [self.computation halfDimension:0] * 2;
    positional.heightModel = [self.computation halfDimension:1] * 2;
    positional.halfTotalThickness = [self.computation halfDimension:2] * [self.delegate defaultThicknessValue];
    positional.nearZ = view.nearZOffset * positional.halfTotalThickness * 4;
    positional.farZ = view.farZOffset * positional.halfTotalThickness * 4;
    positional.stride = (uint32)[self.delegate cellModifierFactor] * 20;
    
    self.positionalBuffer = [self.device newBufferWithBytes:&positional length:sizeof(positional) options:MTLResourceOptionCPUCacheModeDefault];
    
    //Get drawable
    id<CAMetalDrawable> drawable = [view currentDrawable];
    if(!drawable)
        return;
    
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    
    //Create a render pass descriptor
    MTLRenderPassDescriptor * rpd = view.currentRenderPassDescriptor;//[MTLRenderPassDescriptor new];
    if(!rpd)
        return;
    
    id<MTLTexture> text = [drawable texture];
    rpd.colorAttachments[0].texture = drawable.texture;
    rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
    NSColor *bg = [self backGroundColor];
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(bg.redComponent, bg.greenComponent, bg.blueComponent, bg.alphaComponent);
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    
    //Create a command Buffer
    id<MTLCommandBuffer> comBuffer = [self.commandQueue commandBuffer];
    
    //Create encoder for command buffer
    id<MTLRenderCommandEncoder> renderEncoder = [comBuffer renderCommandEncoderWithDescriptor:rpd];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    
    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:self.indexBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:2];
    [renderEncoder setVertexBuffer:self.positionalBuffer offset:0 atIndex:3];
    [renderEncoder setVertexBuffer:self.maskBuffer offset:0 atIndex:4];
    [renderEncoder setVertexBuffer:self.colorBuffer offset:0 atIndex:5];
    [renderEncoder setVertexBuffer:self.centroidsBuffer offset:0 atIndex:6];
    [renderEncoder setVertexBuffer:self.normalsBuffer offset:0 atIndex:7];
    
    AlphaMode alphaMode = [self.delegate alphaMode];
    if(alphaMode == ALPHA_MODE_OPAQUE)
        [renderEncoder setDepthStencilState:self.stencilState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:  MTLCullModeBack ];
    
//    NSInteger segments = self.computation.segmentedUnits;
//    NSInteger cursor = 0;
//    NSInteger step = 5000;
//    NSInteger cumTriangles = 0;
//    NSInteger last = 0;
//    float * copyVerts = self.computation.verts;
//    for (; cursor < segments; cursor += step) {
//        last = cursor + step - 1;
//        if(last >= segments)
//            break;
//        NSInteger triangles = self.computation.cellTriangleOffsets[last] - cumTriangles;
//
//        self.vertexBuffer = [self.device newBufferWithBytes:copyVerts
//                                                     length:triangles * 9 * sizeof(float)
//                                                    options:MTLResourceOptionCPUCacheModeDefault];
//        [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:triangles * 3];
//
//        copyVerts += triangles * 9;
//        cumTriangles += triangles;
//    }
//    NSInteger triangles = self.computation.cellTriangleOffsets[segments - 1] - cumTriangles;
//    self.vertexBuffer = [self.device newBufferWithBytes:copyVerts
//                                                 length:triangles * 9 * sizeof(float)
//                                                options:MTLResourceOptionCPUCacheModeDefault];
//    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
//    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:triangles * 3];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.computation.numberOfTriangles * 3];
    
    [renderEncoder endEncoding];
    
    [comBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer){
        view.lastRenderedTexture = text;
    }];
    
    //Commit
    [comBuffer presentDrawable:drawable];
    [comBuffer commit];
}
-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    [self projectionMatrixSetup:view];
}

-(void)createMetalStack{
    
    //Create pipeline state
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertexShaderPolygonized"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"fragmentShaderPolygonized"];
    
    MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    //Expensive. Do least possible
    NSError *error;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(error)
        NSLog(@"Some error %@ %@", error, error.localizedDescription);
    
    self.commandQueue = [self.device newCommandQueue];
    
    //Stencil
    MTLDepthStencilDescriptor * desc = [MTLDepthStencilDescriptor new];
    desc.depthCompareFunction = MTLCompareFunctionLess;
    desc.depthWriteEnabled = YES;
    self.stencilState = [self.device newDepthStencilStateWithDescriptor:desc];
}

@end

