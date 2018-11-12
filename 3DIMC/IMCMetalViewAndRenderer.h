//
//  IMCMetalViewAndRenderer.h
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "OpenGLView.h"
#import "IMCImageGenerator.h"

typedef struct{
    GLKMatrix4 baseModelMatrix;
    GLKMatrix4 modelViewMatrix;
    GLKMatrix4 projectionMatrix;
    GLKMatrix4 premultipliedMatrix;
    GLKMatrix3 normalMatrix;
} Constants;

typedef struct{
    float leftX;
    float rightX;
    float upperY;
    float lowerY;
    float nearZ;
    float farZ;
    float halfTotalThickness;
    uint32 totalLayers;
    uint32 widthModel;
    uint32 heightModel;
    uint32 areaModel;
    uint32 stride;
    uint32 lastQuad;
} PositionalData;

@class Matrix4;

@interface IMCMetalViewAndRenderer : NSObject <MTKViewDelegate, Get3DData>{
    Matrix4 * projectionMatrix;
}

@property (nonatomic, strong) CAMetalLayer* metalLayer;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> uniformsBuffer;
@property (nonatomic, strong) id<MTLBuffer> positionalBuffer;
@property (nonatomic, strong) id<MTLBuffer> maskBuffer;
//@property (nonatomic, strong) id<MTLBuffer> layerIndexesBuffer;
@property (nonatomic, strong) id<MTLBuffer> colorBuffer;
@property (nonatomic, strong) id<MTLBuffer> heightDescriptor;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLDepthStencilState> stencilState;
@property (nonatomic, strong) NSArray *colorsObtained;
@property (strong, nonatomic) NSArray *indexesObtained;

@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, weak) id<Get3DData> delegate;
@property(nonatomic, assign) BOOL forceColorBufferRecalculation;

-(void)projectionMatrixSetup:(MTKView *)view;
-(BOOL)checkNeedsUpdate;
-(NSColor *)backGroundColor;
-(void)addLabelsOverlayed:(MTKView *)view;

@end
