//
//  IMCMetalPolygonizedFieldRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 11/11/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import "IMCMetalPolygonizedFieldRenderer.h"

@implementation IMCMetalPolygonizedFieldRenderer

@synthesize cellsToRender = _cellsToRender;

-(void)updateColorBuffer{
    
//    _cellsToRender = 0;
//    float ** data = [self.computation computedData];
//    if(data){
//        AlphaMode alphaMode = [self.delegate alphaMode];
//        int stride = 8;
//
//        NSInteger segments = self.computation.segmentedUnits;
//        float * buff = calloc(segments * stride, sizeof(float));
//        if(buff){
//            self.colorsObtained = [self.delegate colors];
//            float minThresholdForAlpha = [self.delegate combinedAlpha];
//
//            float * colors = (float *)malloc(self.colorsObtained.count * 3 * sizeof(float));
//
//            for (int i = 0; i< self.colorsObtained.count; i++) {
//                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
//                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
//                colors[i * 3] = colorObj.redComponent/255.0f;
//                colors[i * 3 + 1] = colorObj.greenComponent/255.0f;
//                colors[i * 3 + 2] = colorObj.blueComponent/255.0f;
//            }
//
//            NSInteger channels = self.indexesObtained.count;
//
//            float * xCentroids = [self.computation xCentroids];
//            float * yCentroids = [self.computation yCentroids];
//            float * zCentroids = [self.computation zCentroids];
//            float minZ = [self.computation minDimension:2];
//
//            float defaultThicknessValue = [self.delegate defaultThicknessValue];
//            if(minZ < .0f)
//                defaultThicknessValue = 1.0f;
//
//            float * sizes = [self.computation sizes];
//
//            float cellModifier = [self.delegate cellModifierFactor];
//            float maxes[channels];
//            for (NSInteger idx = 0; idx < channels; idx++)
//                maxes[idx] = [self.computation maxChannel:[self.indexesObtained[idx]integerValue]];
//
//            for (NSInteger i = 0; i < segments; i++) {
//                NSInteger internalCursor = i * stride;
//                for (NSInteger idx = 0; idx < channels; idx++) {
//                    NSInteger realIndex = [self.indexesObtained[idx]integerValue];
//
//                    UInt8 val = (UInt8)((data[realIndex][i]/maxes[idx]) * 255.0f);
//                    if(self.colorsObtained.count > 0){
//                        buff[internalCursor + 1] += val * colors[idx * 3];
//                        buff[internalCursor + 2] += val * colors[idx * 3 + 1];
//                        buff[internalCursor + 3] += val * colors[idx * 3 + 2];
//                    }else{
//                        RgbColor rgb = RgbFromFloatUnit(val/255.0f);
//                        buff[internalCursor + 1] += rgb.r/255.0f;
//                        buff[internalCursor + 2] += rgb.g/255.0f;
//                        buff[internalCursor + 3] += rgb.b/255.0f;
//                    }
//                    buff[internalCursor + 4] = xCentroids[i];
//                    buff[internalCursor + 5] = yCentroids[i];
//                    buff[internalCursor + 6] = zCentroids[i] * defaultThicknessValue;
//                    buff[internalCursor + 7] = powf((3 * sizes[i]) / (4 * M_PI) , 1.0f/3) * cellModifier;//Size
//
//                    //Filters
//                    float max = .0f;
//                    float sum = .0f;
//                    for (int j = 1; j < 4; j++){
//                        float val = buff[internalCursor + j];
//                        if(val > max)
//                            max = val;
//                        sum += val;
//                        if(sum > 1.0f){
//                            sum = 1.0f;
//                            break;
//                        }
//                    }
//
//                    if(alphaMode == ALPHA_MODE_OPAQUE)
//                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : 1.0f;
//                    if(alphaMode == ALPHA_MODE_FIXED)
//                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : minThresholdForAlpha;//Alpha
//                    if(alphaMode == ALPHA_MODE_ADAPTIVE)
//                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : sum;//MIN(1.0f, sum);//Alpha
//                }
//            }
//            NSInteger bufferSize = segments * stride;
//            float * cleanBuffer = malloc(bufferSize * sizeof(float));
//
//            //Remove all Zeroes
//            NSInteger cleanIndex = 0;
//            for (NSInteger m = 0; m < bufferSize; m+=stride)
//                if(buff[m] > 0){
//                    for (NSInteger n = 0; n < stride; n++)
//                        cleanBuffer[cleanIndex + n] = buff[m + n];
//                    cleanIndex += stride;
//                }
//
//            _cellsToRender = cleanIndex/stride;
//            cleanBuffer = realloc(cleanBuffer, sizeof(float) * cleanIndex);
//            self.colorBuffer = [self.device newBufferWithBytes:cleanBuffer length:cleanIndex * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
//
//            NSLog(@"-%li", _cellsToRender);
//
//            free(buff);
//            //free(cleanBuffer);
//            free(colors);
//        }
//    }
//    NSLog(@"Mem size %li", self.computation.numberOfTriangleVertices * 3 * sizeof(unsigned));
//    NSInteger doTrianglesVertices = 90000000;
//    NSLog(@"Mem size %li instead", doTrianglesVertices * 3 * sizeof(unsigned));
//    self.vertexBuffer = [self.device newBufferWithBytes:self.computation.verts length:doTrianglesVertices * 3 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
    
    self.maskBuffer = [self.device newBufferWithBytes:self.computation.cellTriangleOffsets length:self.computation.segmentedUnits * sizeof(unsigned) options:MTLResourceOptionCPUCacheModeDefault];
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
    uniforms.premultipliedMatrix = GLKMatrix4Multiply(uniforms.projectionMatrix, premultiplied);
    
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
    positional.stride = (uint32)self.computation.segmentedUnits;
    
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
    
//    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:self.positionalBuffer offset:0 atIndex:2];
    [renderEncoder setVertexBuffer:self.maskBuffer offset:0 atIndex:3];
//    [renderEncoder setVertexBuffer:self.colorBuffer offset:0 atIndex:4];
    
    AlphaMode alphaMode = [self.delegate alphaMode];
    if(alphaMode == ALPHA_MODE_OPAQUE)
        [renderEncoder setDepthStencilState:self.stencilState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:  MTLCullModeNone ];
    
    NSInteger segments = self.computation.segmentedUnits;
    NSInteger cursor = 0;
    NSInteger step = 5000;
    NSInteger cumTriangles = 0;
    NSInteger last = 0;
    float * copyVerts = self.computation.verts;
    for (; cursor < segments; cursor += step) {
        last = cursor + step - 1;
        if(last >= segments)
            break;
        NSInteger triangles = self.computation.cellTriangleOffsets[last] - cumTriangles;

        self.vertexBuffer = [self.device newBufferWithBytes:copyVerts
                                                     length:triangles * 9 * sizeof(float)
                                                    options:MTLResourceOptionCPUCacheModeDefault];
        [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:triangles * 3];

        copyVerts += triangles * 9;
        cumTriangles += triangles;
    }
    NSInteger triangles = self.computation.cellTriangleOffsets[segments - 1] - cumTriangles;
    self.vertexBuffer = [self.device newBufferWithBytes:copyVerts
                                                 length:triangles * 9 * sizeof(float)
                                                options:MTLResourceOptionCPUCacheModeDefault];
    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:triangles * 3];
    
//    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.computation.numberOfTriangleVertices];//self.computation.numberOfTriangleVertices];
    
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

