//
//  IMCMetalViewAndRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalViewAndRenderer3DSampler.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import "Matrix4.h"
#import "IMCMtkView.h"

@interface IMCMetalViewAndRenderer3DSampler()

@property (strong, nonatomic) NSIndexSet *slicesObtained;
@property (assign, nonatomic) NSInteger renderWidth;
@property (assign, nonatomic) NSInteger renderHeight;
@property (assign, nonatomic) NSInteger slices;

@end


#define A -0.74, 0.74, 0.0
#define B -0.74, -0.74, 0.0
#define C 0.74, -0.74, 0.0
#define D 0.74, 0.74, 0.0

#define E -0.74, 0.0, 0.74
#define F -0.74, 0.0, -0.74
#define G 0.74, 0.0, -0.74
#define H 0.74, 0.0, 0.74

float squareVertexData[] = {
    A,B,C ,A,C,D,   //Front
    E,F,G ,E,G,H,   //Top
};

const int QUADS_TO_RENDER = 1000;


@implementation IMCMetalViewAndRenderer3DSampler

-(void)addLabelsOverlayed:(MTKView *)view{
    //Will see
}

-(instancetype)init{
    self = [super init];
    if(self){
        
        [self createMetalStack];
    }
    return self;
}


-(void)bakeData{
    //Will see
}

-(NSColor *)backGroundColor{
    return [[self.delegate backgroundColor]colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
}

-(void)projectionMatrixSetup:(MTKView *)view{
    float aspect = fabs(view.bounds.size.width / view.bounds.size.height);
    projectionMatrix = [Matrix4 makePerspectiveViewAngle:[Matrix4 degreesToRad:65.0] aspectRatio:aspect nearZ:0.01 farZ:1500];
}

-(NSArray *)onlyExternals:(NSIndexSet *)indexSet inArrangedArray:(NSArray *)idx{
    NSMutableArray *res = @[].mutableCopy;

    for (NSArray *arr in idx)
        for (NSNumber *num in arr)
            if([indexSet containsIndex:num.integerValue]){
                [res addObject:@([idx indexOfObject:arr])];
                break;
            }
    return res;
}

-(void)updateColorBufferWithWidth:(NSInteger)width height:(NSInteger)height{
    
    UInt8 *** data = [self.delegate threeDData];
    float * zPositions = [self.delegate zValues];
    float * zThicknesses = [self.delegate thicknesses];
    NSIndexSet *slices = [self.delegate stacksIndexSet];
    NSArray *arranged = [self.delegate inOrderIndexesArranged];
    NSArray *externals = [self onlyExternals:slices inArrangedArray:arranged];
    
    float minThresholdForAlpha = [self.delegate combinedAlpha];
    UInt8 thresholdAlpha = (UInt8) (minThresholdForAlpha * 255);
    
    
    
    if(data && zPositions && zThicknesses){
        NSInteger area = width * height;
        CGRect rectToRender = [self.delegate rectToRender];
        AlphaMode alphaMode = [self.delegate alphaMode];
        self.slices = externals.count;
        int stride = 4;
        
        bool * mask = [self.delegate showMask];
        NSInteger ascertainWidth = 0;
        NSInteger firstToProcess = 0;
        for (NSInteger i = 0; i < area; i++) {
            if(mask[i] == true){
                firstToProcess = i;
                while (mask[i] == true) {
                    ascertainWidth++;
                    i++;
                }
                break;
            }
        }
        self.renderWidth = ascertainWidth;
        self.renderHeight = (NSInteger)round((fabs(rectToRender.size.height) * height));
        NSInteger renderableArea = self.renderWidth * self.renderHeight;
        NSInteger last = MIN(_renderHeight * width + firstToProcess, area);
        
        UInt8 * buff = calloc(renderableArea * externals.count * stride, sizeof(UInt8));
        
        if(buff){
            __block NSInteger x , y, cursor = 0;
            __block float  z = 0.0f, thickness = 0.0f;
            
            float * reverseIndex = (float *)calloc(QUADS_TO_RENDER, sizeof(float));//TODO, the number of of quads. Coincides with instance cound and 1000 in fragment shader
            for(int i = 0; i < QUADS_TO_RENDER; ++i)
                reverseIndex[i] = -1;
            
            self.colorsObtained = [self.delegate colors];
            
            UInt8 * colors = (UInt8 *)malloc(self.colorsObtained.count * 3 * sizeof(UInt8));
            
            for (int i = 0; i< self.colorsObtained.count; i++) {
                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
                colors[i * 3] = (UInt8)colorObj.redComponent;
                colors[i * 3 + 1] = (UInt8)colorObj.greenComponent;
                colors[i * 3 + 2] = (UInt8)colorObj.blueComponent;
            }
            NSInteger numColors = self.colorsObtained.count;
            
            NSInteger realIndexesCount = self.indexesObtained.count;
            NSInteger realIndexes[realIndexesCount];
            for (NSInteger i = 0; i < self.indexesObtained.count; i++)
                realIndexes[i] = [self.indexesObtained[i]integerValue];
            
            float quadsPerMicron = QUADS_TO_RENDER / (zPositions[[[arranged.lastObject firstObject] integerValue]] + zThicknesses[[[arranged.lastObject firstObject] integerValue]]);
            
            for (NSNumber *num in externals) {
                NSInteger corresponding = num.integerValue;
                UInt8 ** sliceData = data[corresponding];
                
                if(sliceData){
                    x = 0;
                    y = 0;
                    z = zPositions[[[arranged[corresponding]firstObject]integerValue]];
                    thickness = zThicknesses[[[arranged[corresponding]firstObject]integerValue]];
                    
                    for (int s = round(z * quadsPerMicron); s < round((z + thickness) * quadsPerMicron); ++s)
                        if(s >= 0 && s < QUADS_TO_RENDER)
                            reverseIndex[s] =  cursor / (renderableArea * stride);
                    
                    UInt8 *chanData = NULL;
                    
                    for (NSInteger idx = 0; idx < realIndexesCount; idx++) {
                        NSInteger realIndex = realIndexes[idx];
                        
                        chanData = sliceData[realIndex];
                        if(chanData){
                            NSInteger internalCursor = 0;
                            
                            for (NSInteger pix = firstToProcess; pix < last; pix++) {
                                
                                if(mask[pix] == false)
                                    continue;
                                
                                NSInteger internalStride = cursor + internalCursor * stride;
                                
                                if(numColors > 0){
                                    buff[internalStride + 1] = MIN(255, buff[internalStride + 1] + (UInt8)(chanData[pix] * colors[idx * 3]));
                                    buff[internalStride + 2] = MIN(255, buff[internalStride + 2] + (UInt8)(chanData[pix] * colors[idx * 3 + 1]));
                                    buff[internalStride + 3] = MIN(255, buff[internalStride + 3] + (UInt8)(chanData[pix] * colors[idx * 3 + 2]));
                                }else{
                                    RgbColor rgb = RgbFromFloatUnit(chanData[pix]/255.0f);
                                    buff[internalStride + 1] = MIN(255, buff[internalStride + 1] + rgb.r);
                                    buff[internalStride + 2] = MIN(255, buff[internalStride + 2] + rgb.g);
                                    buff[internalStride + 3] = MIN(255, buff[internalStride + 3] + rgb.b);
                                }

                                //Filters
                                UInt8 max = 0, sum = 0;
                                for (int i = 1; i < 4; i++){
                                    UInt8 val = buff[internalStride + i];
                                    max = MAX(val, max);
                                    UInt16 tmp = sum + val;
                                    sum = MIN(tmp, 255);
                                }
                                if(alphaMode == ALPHA_MODE_OPAQUE)
                                    buff[internalStride] = max < thresholdAlpha ? 0 : 255;
                                else if(alphaMode == ALPHA_MODE_FIXED)
                                    buff[internalStride] = max < thresholdAlpha ? 0 : thresholdAlpha;//Alpha
                                else if(alphaMode == ALPHA_MODE_ADAPTIVE)
                                    buff[internalStride] = max < thresholdAlpha ? 0 : sum;
                                internalCursor++;
                            }
                        }
                    }
                }
                cursor += renderableArea * stride;
            }
            int first = -1, last = 0;
            for(int a = 0; a < QUADS_TO_RENDER; ++a){
                if(reverseIndex[a] != -1 && first == -1)
                    first = a;
                if(reverseIndex[a] != -1)
                    last = a;
            }
            float * reverseIndexCopy = (float *)calloc(QUADS_TO_RENDER, sizeof(float));
            for(int a = 0; a < QUADS_TO_RENDER; ++a)
                reverseIndexCopy[a] = -1;
            int halfInReverse = QUADS_TO_RENDER/2;
            int middleReverse = (last - first)/2;
            for(int a = 0; a < last; ++a){
                int newIndex = halfInReverse - middleReverse - 1;
                if(newIndex >= QUADS_TO_RENDER)
                    break;
                reverseIndexCopy[newIndex + a] = reverseIndex[a];
            }
            
            NSInteger bufferSize = renderableArea * externals.count * stride;
            
            if(bufferSize < 1024000000)
                self.colorBuffer = [self.device newBufferWithBytes:buff length:bufferSize options:MTLResourceOptionCPUCacheModeDefault];
            else
                self.colorBuffer = nil;
            
            self.heightDescriptor = [self.device newBufferWithBytes:reverseIndexCopy length:QUADS_TO_RENDER * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            
            free(buff);
            free(colors);
            free(reverseIndex);
            free(reverseIndexCopy);
        }
    }
}



-(void)drawInMTKView:(IMCMtkView *)view{
    view.framebufferOnly = NO;
    if(view.refresh == NO && !self.forceColorBufferRecalculation)
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
    
    bool invertible;
    uniforms.modelViewMatrix = GLKMatrix4Invert(view.rotationMatrix->glkMatrix, &invertible);
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
    positional.halfTotalThickness = [self.delegate zValues][self.delegate.stacksIndexSet.lastIndex]/2;
    positional.nearZ = view.nearZOffset * positional.halfTotalThickness * 2;
    positional.farZ = view.farZOffset * positional.halfTotalThickness * 2;
    positional.widthModel = (uint)self.renderWidth;
    positional.heightModel = (uint)self.renderHeight;
    positional.totalLayers = (uint)self.slices;
    positional.areaModel = (uint)(self.renderWidth * self.renderHeight);
    positional.stride = 1;
    
    self.positionalBuffer = [self.device newBufferWithBytes:&positional length:sizeof(positional) options:MTLResourceOptionCPUCacheModeDefault];
    
    //prepareData
    if([self checkNeedsUpdate] || self.forceColorBufferRecalculation)
        [self updateColorBufferWithWidth:width height:height];
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
    
    [renderEncoder setVertexBuffer:self.positionalBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:self.uniformsBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
    
    [renderEncoder setFragmentBuffer:self.colorBuffer offset:0 atIndex:0];
    [renderEncoder setFragmentBuffer:self.positionalBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBuffer:self.heightDescriptor offset:0 atIndex:2];
    
    AlphaMode alphaMode = [self.delegate alphaMode];
    if(alphaMode == ALPHA_MODE_OPAQUE)
        [renderEncoder setDepthStencilState:self.stencilState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:  MTLCullModeNone ];
    
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:QUADS_TO_RENDER];
//    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:6 vertexCount:6 instanceCount:QUADS_TO_RENDER];
//    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:2];
//    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:QUADS_TO_RENDER];
    
    [renderEncoder endEncoding];
    
    [comBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer){
        //view.refresh = NO;
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

    NSInteger dataSize = sizeof(squareVertexData);
    self.vertexBuffer = [self.device newBufferWithBytes:squareVertexData length:dataSize options:MTLResourceOptionCPUCacheModeDefault];

    //Create pipeline state
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertexShaderBack"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"fragmentShaderBack"];
    
    MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    
    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceColor;
    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceColor;
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceColor;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceColor;
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationMax;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm; ////// Kontuz. Must coincide with CAMetalLayer
    
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
