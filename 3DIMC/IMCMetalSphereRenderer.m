//
//  IMCMetalSphereRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 11/18/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalSphereRenderer.h"
#import "IMCMtkView.h"
#import "sphere.h"

@interface IMCMetalSphereRenderer()

@end

@implementation IMCMetalSphereRenderer

-(instancetype)initWith3DMask:(IMC3DMask *)mask3D{
    self = [self init];
    if(self){
    
    }
    return self;
}

-(void)updateColorBuffer{
    
    _cellsToRender = 0;
    float ** data = [self.computation computedData];
    if(data){
        AlphaMode alphaMode = [self.delegate alphaMode];
        int stride = 8;
        
        NSInteger segments = self.computation.segmentedUnits;
        float * buff = calloc(segments * stride, sizeof(float));
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
            
            NSInteger channels = self.indexesObtained.count;
            
            float * xCentroids = [self.computation xCentroids];
            float * yCentroids = [self.computation yCentroids];
            float * zCentroids = [self.computation zCentroids];
            float * sizes = [self.computation sizes];
            float defaultThicknessValue = [self.delegate defaultThicknessValue];
            float maxes[channels];
            for (NSInteger idx = 0; idx < channels; idx++)
                maxes[idx] = [self.computation maxChannel:[self.indexesObtained[idx]integerValue]];
            
            for (NSInteger i = 0; i < segments; i++) {
                NSInteger internalCursor = i * stride;
                for (NSInteger idx = 0; idx < channels; idx++) {
                    NSInteger realIndex = [self.indexesObtained[idx]integerValue];
                    
                    UInt8 val = (UInt8)((data[realIndex][i]/maxes[idx]) * 255.0f);
                    if(self.colorsObtained.count > 0){
                        buff[internalCursor + 1] += val * colors[idx * 3];
                        buff[internalCursor + 2] += val * colors[idx * 3 + 1];
                        buff[internalCursor + 3] += val * colors[idx * 3 + 2];
                    }else{
                        RgbColor rgb = RgbFromFloatUnit(val/255.0f);
                        buff[internalCursor + 1] += rgb.r/255.0f;
                        buff[internalCursor + 2] += rgb.g/255.0f;
                        buff[internalCursor + 3] += rgb.b/255.0f;
                    }
                    buff[internalCursor + 4] = xCentroids[i];
                    buff[internalCursor + 5] = yCentroids[i];
                    buff[internalCursor + 6] = zCentroids[i] * defaultThicknessValue;
                    buff[internalCursor + 7] = powf((3 * sizes[i]) / (4 * M_PI) , 1.0f/3);//Size
                    
                    //Filters
                    float max = .0f;
                    float sum = .0f;
                    for (int j = 1; j < 4; j++){
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
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : 1.0f;
                    if(alphaMode == ALPHA_MODE_FIXED)
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : minThresholdForAlpha;//Alpha
                    if(alphaMode == ALPHA_MODE_ADAPTIVE)
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : sum;//MIN(1.0f, sum);//Alpha
                }
            }
            NSInteger bufferSize = segments * stride;
            float * cleanBuffer = malloc(bufferSize * sizeof(float));
            
            //Remove all Zeroes
            NSInteger cleanIndex = 0;
            for (NSInteger m = 0; m < bufferSize; m+=stride)
                if(buff[m] > 0){
                    for (NSInteger n = 0; n < stride; n++)
                        cleanBuffer[cleanIndex + n] = buff[m + n];
                    cleanIndex += stride;
                }

            _cellsToRender = cleanIndex/stride;
            cleanBuffer = realloc(cleanBuffer, sizeof(float) * cleanIndex);
            self.colorBuffer = [self.device newBufferWithBytes:cleanBuffer length:cleanIndex * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            
            NSLog(@"-%li", _cellsToRender);
            
            free(buff);
            //free(cleanBuffer);
            free(colors);
        }
    }
}


-(void)drawInMTKView:(IMCMtkView *)view{
    view.framebufferOnly = NO;
    if(view.refresh == NO && !self.forceColorBufferRecalculation)
        return;
    if(!self.computation || !self.computation.isLoaded)
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
    
    //Positional Data
    PositionalData positional;
    positional.lowerY = view.lowerYOffset * height;
    positional.upperY = view.upperYOffset * height;
    positional.leftX = view.leftXOffset * width;
    positional.rightX = view.rightXOffset * width;
    positional.widthModel = [self.computation halfDimension:0] + [self.computation minDimension:0];
    positional.heightModel = [self.computation halfDimension:1] + [self.computation minDimension:1];
    positional.halfTotalThickness = [self.computation halfDimension:2] * [self.delegate defaultThicknessValue];
    positional.nearZ = view.nearZOffset * positional.halfTotalThickness * 2;
    positional.farZ = view.farZOffset * positional.halfTotalThickness * 2;
    
    self.positionalBuffer = [self.device newBufferWithBytes:&positional length:sizeof(positional) options:MTLResourceOptionCPUCacheModeDefault];
    
    //prepareData
    
    if([self checkNeedsUpdate] || self.forceColorBufferRecalculation)
        [self updateColorBuffer];
    self.forceColorBufferRecalculation = NO;
    
    if(!self.colorBuffer)
        return;
    
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
    [renderEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:self.positionalBuffer offset:0 atIndex:2];
    [renderEncoder setVertexBuffer:self.colorBuffer offset:0 atIndex:3];
    
    AlphaMode alphaMode = [self.delegate alphaMode];
    if(alphaMode == ALPHA_MODE_OPAQUE)
        [renderEncoder setDepthStencilState:self.stencilState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:  MTLCullModeNone ];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sphereNumVerts instanceCount:_cellsToRender];
    
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
    
    //Add VD for cube
    NSInteger dataSize = sizeof(sphereVerts);
    self.vertexBuffer = [self.device newBufferWithBytes:sphereVerts length:dataSize options:MTLResourceOptionCPUCacheModeDefault];

    //Create pipeline state
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"sphereVertexShader"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"sphereFragmentShader"];
    
    MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;

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
