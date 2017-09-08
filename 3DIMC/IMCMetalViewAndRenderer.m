//
//  IMCMetalViewAndRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalViewAndRenderer.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import "Matrix4.h"
#import "IMCMtkView.h"

@interface IMCMetalViewAndRenderer(){
    Matrix4 * projectionMatrix;
    float zoom;
}

@property (nonatomic, strong) CAMetalLayer* metalLayer;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformsBuffer;
@property (nonatomic, strong) id<MTLBuffer> positionalBuffer;
@property (nonatomic, strong) id<MTLBuffer> maskBuffer;
@property (nonatomic, strong) id<MTLBuffer> layerIndexesBuffer;
@property (nonatomic, strong) id<MTLBuffer> colorBuffer;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLDepthStencilState> stencilState;
@property (nonatomic, strong) NSArray *colorsObtained;
@property (strong, nonatomic) NSArray *indexesObtained;
@property (assign, nonatomic) NSInteger renderWidth;
@property (assign, nonatomic) NSInteger renderHeight;
@property (assign, nonatomic) NSInteger slices;

@end

typedef struct{
    GLKMatrix4 baseModelMatrix;
    GLKMatrix4 modelViewMatrix;
    GLKMatrix4 projectionMatrix;
    GLKMatrix3 normalMatrix;
} Constants;

typedef struct{
    float leftX;
    float rightX;
    float upperY;
    float lowerY;
    float totalThickness;
    uint32 totalLayers;
    uint32 widthModel;
    uint32 heightModel;
    uint32 areaModel;
} PositionalData;

float vertexData[] = {0.0, 1.0, 0.0,
                      -1.0, -1.0, 0.0,
                      1.0, -1.0, 0.0
};

typedef struct{
    float x, y, z, w;
} Vertex;

#define A -0.5, 0.5, 0.5
#define B -0.5, -0.5, 0.5
#define C 0.5, -0.5, 0.5
#define D 0.5, 0.5, 0.5

#define Q -0.5, 0.5, -0.5
#define R 0.5,  0.5, -0.5
#define S -0.5, -0.5, -0.5
#define T 0.5, -0.5, -0.5

float cubeVertexData[] = {
    A,B,C ,A,C,D,   //Front
    R,T,S ,Q,R,S,   //Back
    
    Q,S,B ,Q,B,A,   //Left
    D,C,T ,D,T,R,   //Right
    
    Q,A,D ,Q,D,R,   //Top
    B,S,T ,B,T,C    //Bot
};


@implementation IMCMetalViewAndRenderer


-(instancetype)init{
    self = [super init];
    if(self){

        [self createMetalStack];
    }
    return self;
}


-(void)bakeData{

}

-(NSColor *)backGroundColor{
    return [[self.delegate backgroundColor]colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
}

-(void)projectionMatrixSetup:(MTKView *)view{
    float aspect = fabs(view.bounds.size.width / view.bounds.size.height);
    projectionMatrix = [Matrix4 makePerspectiveViewAngle:[Matrix4 degreesToRad:65.0] aspectRatio:aspect nearZ:0.01 farZ:1000];
}

-(BOOL)checkNeedsUpdate{
    BOOL update = NO;
    
    //Check colors
    NSArray * currentColors = [self.delegate colors];
    if(self.colorsObtained.count != currentColors.count)
        update = YES;
    
    else
        for (NSInteger i = 0; i < self.colorsObtained.count; i++){
            NSColor *a = self.colorsObtained[i];
            NSColor *b = currentColors[i];
            
            a = [a colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
            b = [b colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
            if(!CGColorEqualToColor(a.CGColor, b.CGColor))
                update = YES;
        }
    
    //Check Indexes
    NSArray *currentIndexes = [self.delegate inOrderIndexes].copy;
    if(self.indexesObtained.count != currentIndexes.count)
        update = YES;
    
    else
        for (NSInteger i = 0; i < self.indexesObtained.count; i++)
            if([self.indexesObtained[i] integerValue] != [currentIndexes[i] integerValue])
                update = YES;
    
//    if(bufferDataLayers != bufferDataLayersLoaded)
//        update = YES;
    
    if(update == YES){
        self.colorsObtained = currentColors;
        self.indexesObtained = currentIndexes;
    }
    
    return update;
}

-(void)syntheticCubes{
    float vals[] ={
        1.0f, 1.0f, 0.0f, 0.0f, -1.0f, -1.0f, -1.0f,
        1.0f, 0.0f, 1.0f, 0.0f, -1.0f, 1.0f, -1.0f,
        1.0f, 0.0f, 0.0f, 1.0f, 1.0f, -1.0f, -1.0f,
        1.0f, 0.0f, 1.0f, 1.0f, 1.0f, 1.0f, -1.0f,
        
        1.0f, 1.0f, 0.0f, 1.0f, -1.0f, -1.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 0.0f, -1.0f, 1.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f, 1.0f, -1.0f, 1.0f,
        0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f
    };
    
    self.colorBuffer = [self.device newBufferWithBytes:vals length: 8 * 7 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
}

-(void)updateColorBufferWithWidth:(NSInteger)width height:(NSInteger)height slices:(NSInteger)slices{
    
    [self syntheticCubes];
    return;
    
    float *** data = [self.delegate threeDData];
    if(data){
        NSInteger area = width * height;
        CGRect rectToRender = [self.delegate rectToRender];

        self.renderWidth = (NSInteger)ceilf(rectToRender.size.width * width);
        self.renderHeight = (NSInteger)ceilf(rectToRender.size.height * height);
        self.slices = slices;
        
        float * buff = calloc(self.renderWidth * self.renderHeight * slices * 6, sizeof(float));//Color components and positions
        if(buff){
            float x , y, z = .0f;
            
            self.colorsObtained = [self.delegate colors];
            self.indexesObtained = [self.delegate inOrderIndexes].copy;
            float minThresholdForAlpha = [self.delegate combinedAlpha];
            
            bool * mask = [self.delegate showMask];
            
            float * colors = (float *)malloc(self.colorsObtained.count * 3 * sizeof(float));
            for (int i = 0; i< self.colorsObtained.count; i++) {
                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
                colors[i * 3] = colorObj.redComponent;;
                colors[i * 3 + 1] = colorObj.greenComponent;;
                colors[i * 3 + 2] = colorObj.blueComponent;
            }
            
            int stride = 7;
            
            NSInteger cursor = 0;
            for (NSInteger slice = 0; slice < slices; slice++) {
                float ** sliceData = data[slice];
                if(sliceData){
                    x = .0f;
                    y = .0f;
                    for (NSInteger idx = 0; idx < self.indexesObtained.count; idx++) {
                        float *chanData = sliceData[idx];
                        if(chanData){
                            for (NSInteger pix = 0; pix < area; pix++) {
                                if(mask[pix] == false)
                                    continue;
                                buff[cursor + pix * stride + 1] += chanData[pix] * colors[idx * 3];
                                buff[cursor + pix * stride + 2] += chanData[pix] * colors[idx * 3 + 1];
                                buff[cursor + pix * stride + 3] += chanData[pix] * colors[idx * 3 + 2];
                                buff[cursor + pix * stride + 4] = x;
                                buff[cursor + pix * stride + 5] = y;
                                buff[cursor + pix * stride + 6] = z;
                                
                                x += 1.0f;
                                if(x == self.renderWidth){
                                    y += 1.0f;
                                    x = 0.0f;
                                }
                                //Filters
                                float max = .0f;
                                float sum = .0f;
                                for (int i = 1; i < 4; i++){
                                    float val = buff[cursor + pix * stride + i];
                                    if(val > max)
                                        max = val;
                                    if(val > 1.0f)
                                        buff[cursor + pix * stride + i] = 1.0f;
                                    sum += val;
                                }
                                buff[cursor + pix * stride] = max < minThresholdForAlpha ? 0.0f : MIN(1.0f, sum);//Alpha
                            }
                        }
                    }
                }
                z += 1.0f;
                cursor += area * 3;
            }
            if(self.renderWidth * self.renderHeight * slices * 6 * sizeof(float) < 1024000000)
                self.colorBuffer = [self.device newBufferWithBytes:buff length:self.renderWidth * self.renderHeight * slices * 6 * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            else
                self.colorBuffer = nil;
            free(buff);
            free(colors);
        }
    }
}

-(void)drawInMTKView:(IMCMtkView *)view{
    
    if(view.refresh == NO)
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
    
    self.uniformsBuffer = [self.device newBufferWithBytes:&uniforms length:sizeof(uniforms) options:MTLResourceOptionCPUCacheModeDefault];
    
    PositionalData positional;
    positional.lowerY = view.lowerY;
    positional.upperY = view.upperY;
    positional.leftX = view.leftX;
    positional.rightX = view.rightX;
    positional.widthModel = (uint)self.renderWidth;
    positional.heightModel = (uint)self.renderHeight;
    positional.totalLayers = (uint)self.slices;
    
    self.positionalBuffer = [self.device newBufferWithBytes:&positional length:sizeof(positional) options:MTLResourceOptionCPUCacheModeDefault];
    
    //Size model
    NSInteger width = [self.delegate witdhModel];
    NSInteger height = [self.delegate heightModel];
    NSInteger areaModel = width * height;
    NSInteger slices = [self.delegate numberOfStacks];
    
    //Slice handling
    float * zPositions = [self.delegate zValues];
    float * zThicknesses = [self.delegate thicknesses];
    if(zPositions == NULL || zThicknesses == NULL)
        return;
    float * collatedZ = calloc(slices * 3, sizeof(float));
    [[self.delegate stacksIndexSet] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        collatedZ[idx * 3 + 0] = 1.0f;
        collatedZ[idx * 3 + 1] = zPositions[idx];
        collatedZ[idx * 3 + 2] = zThicknesses[idx];
    }];
    self.layerIndexesBuffer = [self.device newBufferWithBytes:collatedZ length:self.slices * sizeof(float) * 3 options:MTLResourceOptionCPUCacheModeDefault];
    free(collatedZ);
    
    //prepareData
    if([self checkNeedsUpdate])
        [self updateColorBufferWithWidth:width height:height slices:slices];
    if(!self.colorBuffer)
        return;
    
    //Mask //TODO. Not do everytime
    bool * mask = [self.delegate showMask];
    if(mask)
        self.maskBuffer = [self.device newBufferWithBytes:mask length:areaModel options:MTLResourceOptionCPUCacheModeDefault];//cpuCacheModeWriteCombined
    else
        return;
    
    //Get drawable
    id<CAMetalDrawable> drawable = [view currentDrawable];
    if(!drawable)
        return;
    //Create a render pass descriptor
    MTLRenderPassDescriptor * rpd = view.currentRenderPassDescriptor;//[MTLRenderPassDescriptor new];
    if(!rpd)
        return;
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
    [renderEncoder setVertexBuffer:self.maskBuffer offset:0 atIndex:3];
    [renderEncoder setVertexBuffer:self.layerIndexesBuffer offset:0 atIndex:4];
    [renderEncoder setVertexBuffer:self.colorBuffer offset:0 atIndex:5];
    NSLog(@"%@", self.stencilState);
    [renderEncoder setDepthStencilState:self.stencilState];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setCullMode:MTLCullModeBack];
    
    //[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sizeof(cubeVertexData)];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36 instanceCount:8];//self.renderWidth * self.renderHeight * self.slices];
    
    [renderEncoder endEncoding];
    
//    [comBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer){
//        view.refresh = NO;
//    }];
    
    //Commit
    [comBuffer presentDrawable:drawable];
    [comBuffer commit];
}
-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size{
    [self projectionMatrixSetup:view];
}

-(void)createMetalStack{
    //Create layer
    //_metalLayer = [[CAMetalLayer alloc]init];
    //_metalLayer.device = self.device;
    //_metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //_metalLayer.framebufferOnly = YES;
    //_metalLayer.frame = self.bounds;
    //[_layer addSublayer:_metalLayer];
    
    NSLog(@"%@", MTLCreateSystemDefaultDevice());
    NSLog(@"%@", MTLCopyAllDevices());
    NSLog(@"%@", self.device);
    
    //Add VD for cube
    NSInteger dataSize = sizeof(cubeVertexData);
    self.vertexBuffer = [self.device newBufferWithBytes:cubeVertexData length:dataSize options:MTLResourceOptionCPUCacheModeDefault];
    //Create pipeline state
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
//    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
//    
//    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
//    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
//    pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
//    pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
//    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
//    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm; ////// Kontuz. Must coincide with CAMetalLayer
    
    //Expensive. Do least possible
    NSError *error;
    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(error)
        NSLog(@"Some error %@ %@", error, error.localizedDescription);
    
    _commandQueue = [self.device newCommandQueue];
    
    //Stencil
    MTLDepthStencilDescriptor * desc = [MTLDepthStencilDescriptor new];
    desc.depthCompareFunction = MTLCompareFunctionLess;
    desc.depthWriteEnabled = YES;
    self.stencilState = [self.device newDepthStencilStateWithDescriptor:desc];
}

-(void)touchesBeganWithEvent:(NSEvent *)event{
    //[self render];
}

@end
