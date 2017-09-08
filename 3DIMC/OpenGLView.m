//
//  MyView.m
//  exosx
//
//  Created by Jay Anderson on 8/13/12.
//  Copyright (c) 2012 Jay Anderson. All rights reserved.
//
// Intended for Chapter 8, "Some Objects; a Camera View," of the iBook
// "OpenGL for Apple Software Developers," © 2014 Jay Martin Anderson.

#import "OpenGLView.h"
#import "IMCScale.h"

@interface OpenGLView()
{
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix3 _normalMatrix;
    GLuint vertexBuffer;
    GLuint vertexArray;
    
    GLuint texName;
    
    GLKMatrix4 _rotMatrix;
    float *colors;
    
    BOOL working;
    float ** bufferedData;
    int bufferDataLayers;
    int bufferDataLayersLoaded;
}
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) NSArray *lastLabels;
@property (strong, nonatomic) NSArray *colorsObtained;
@property (strong, nonatomic) NSArray *indexesObtained;

@end

@implementation OpenGLView


//-(void)renderSimpleCube{
//    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
//    self.effect.material.emissiveColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
//    
//    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(
//                                                               0.0f,//
//                                                               0.0f,//Sacar valores correctos
//                                                               -20.0f);
//    //baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotation, 1.0f, 0.0f, 0.0f);
//    
//    //    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -100.0f);
//    //    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0f, 0.0f, 1.0f);
//    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeRotation(rotation.x, 1.0f, 0.0f, 0.0f);
//    modelViewMatrix = GLKMatrix4MakeRotation(rotation.y, 0.0f, 1.0f, 0.0f);
//    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0.0f, 0.0f, -10.0f);
//    
//    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
//    self.effect.transform.modelviewMatrix = modelViewMatrix;
//    // It may be wise to be sure the OpenGL context we established is the current context
//    
//    [self.effect prepareToDraw];
//    
//    // draw the sphere from the appropriate vertex array
//    glDrawArrays(GL_TRIANGLES, 0, 36);
//    [[self openGLContext] flushBuffer];
//}

//GLfloat gCubeVertexData[216] =
//{
//    // Data layout for each line below is:
//    // positionX, positionY, positionZ, normalX, normalY, normalZ,
//    0.5f, -0.5f, -0.5f, 1.0f, 0.0f, 0.0f,
//    0.5f, 0.5f, -0.5f, 1.0f, 0.0f, 0.0f,
//    0.5f, -0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
//    0.5f, -0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
//    0.5f, 0.5f, -0.5f, 1.0f, 0.0f, 0.0f,
//    0.5f, 0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
//
//    0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f,
//    0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
//    0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, -0.5f, 0.0f, 1.0f, 0.0f,
//    -0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
//
//    -0.5f, 0.5f, -0.5f, -1.0f, 0.0f, 0.0f,
//    -0.5f, -0.5f, -0.5f, -1.0f, 0.0f, 0.0f,
//    -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
//    -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
//    -0.5f, -0.5f, -0.5f, -1.0f, 0.0f, 0.0f,
//    -0.5f, -0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
//
//    -0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f,
//    -0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
//    -0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, -0.5f, 0.0f, -1.0f, 0.0f,
//    0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
//
//    0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//    -0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//    0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//    0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//    -0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//    -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
//
//    0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f,
//    -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f,
//    0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f,
//    0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f,
//    -0.5f, -0.5f, -0.5f, 0.0f, 0.0f, -1.0f,
//    -0.5f, 0.5f, -0.5f, 0.0f, 0.0f, -1.0f
//};


typedef struct
{
    GLfloat position[3];
    GLfloat color[4];
} Vertex;                           // this vertex structure contains ONLY position & color information!


#define BUFFER_OFFSET(i) ((char *)NULL + (i))

//Cube/Prism with 2 strips. Performance optimization
#define VERTEX_COUNT 156

#define CUBE_PROX_LL -0.5f, -0.5f, 0.5f
#define CUBE_PROX_LR 0.5f, -0.5f, 0.5f
#define CUBE_PROX_UL -0.5f, 0.5f, 0.5f
#define CUBE_PROX_UR 0.5f, 0.5f, 0.5f
#define CUBE_DIST_LL -0.5f, -0.5f, (-0.5f * height)
#define CUBE_DIST_LR 0.5f, -0.5f, (-0.5f * height)
#define CUBE_DIST_UL -0.5f, 0.5f, (-0.5f * height)
#define CUBE_DIST_UR 0.5f, 0.5f, (-0.5f * height)

#define CUBE_NORMAL_FRONT .0f, .0f, 1.0f
#define CUBE_NORMAL_RIGHT 1.0f, .0f, .0f
#define CUBE_NORMAL_BACK .0f, .0f, -1.0f
#define CUBE_NORMAL_TOP .0f, 1.0f, .0f
#define CUBE_NORMAL_LEFT -1.0f, .0f, .0f
#define CUBE_NORMAL_BOTTOM .0f, -1.0f, .0f

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        NSOpenGLPixelFormatAttribute pixelFormatAttributes[] =
        {
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            NSOpenGLPFADoubleBuffer, YES,
            NSOpenGLPFADepthSize, 32,
            0
        };
        NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttributes];
        
        NSOpenGLContext *oglContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
        
        [self setOpenGLContext:oglContext];
        [self.openGLContext makeCurrentContext];
    }
    return self;
}
-(void)awakeFromNib{
    [super awakeFromNib];
    self.wantsLayer = YES;
}

-(void)prepareOpenGL
{
    
    [self.openGLContext setView:self];
    
    glClearColor(0.15f, 0.15f, 0.15f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArrays(1, &vertexArray);
    glGenBuffers(1, &vertexBuffer);
    glBindVertexArray(vertexArray);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    //glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24,
                          BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24,
                          BUFFER_OFFSET(12));
    
    /*glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24,//GL_FALSE
                          BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24,
                          BUFFER_OFFSET(12));*/
    
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    
    [self prepareVertexBuffer];
    [self projectMatrix];
    
    _rotMatrix = GLKMatrix4Identity;
    
    [self.openGLContext makeCurrentContext];
    //[self setWantsBestResolutionOpenGLSurface:YES];
}

-(void)prepareVertexBuffer{
    //  It used to be like this, but now I generate the prisma dynamically
    //    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData),
    //                 gCubeVertexData, GL_STATIC_DRAW);
    //    And then like this
    //    GLfloat final[216];
    //    for (int x = 0; x<216; x++) {
    //        final[x] = floats[x];
    //    }
    //glBufferData(GL_ARRAY_BUFFER, sizeof(final),
    //             final, GL_STATIC_DRAW);
    GLfloat *floats = [self generateCubeWithHeigth:self.defaultThickness];
    glBufferData(GL_ARRAY_BUFFER, 216 * sizeof(GLfloat),
                 (void *)floats, GL_STATIC_DRAW);
    
    //GLfloat *floats = [self generateVerticesForStripDoneCube:self.defaultThickness];
    //glBufferData(GL_ARRAY_BUFFER, VERTEX_COUNT * sizeof(GLfloat),
    //             (void *)floats, GL_STATIC_DRAW);
    
    free(floats);
}

-(void)projectMatrix{
    float aspect = fabs(self.bounds.size.width / self.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 1500.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

-(GLfloat *)generateVerticesForStripDoneCube:(GLfloat)heightOfCube{
    GLfloat height = (heightOfCube * 2) - 1.0f;
    GLfloat gCubeVertexDataLocal[VERTEX_COUNT] =
    {
        
        CUBE_PROX_UL, CUBE_NORMAL_FRONT,
        CUBE_PROX_LL, CUBE_NORMAL_FRONT,
        CUBE_PROX_UR, CUBE_NORMAL_FRONT,
        CUBE_PROX_LR, CUBE_NORMAL_FRONT,
        CUBE_DIST_UR, CUBE_NORMAL_RIGHT,
        CUBE_DIST_LR, CUBE_NORMAL_RIGHT,
        CUBE_DIST_UL, CUBE_NORMAL_BACK,
        CUBE_DIST_LL, CUBE_NORMAL_BACK,
        
        CUBE_PROX_UR, CUBE_NORMAL_TOP,
        CUBE_DIST_UR, CUBE_NORMAL_TOP,
        CUBE_PROX_UL, CUBE_NORMAL_TOP,
        CUBE_DIST_UL, CUBE_NORMAL_TOP,
        CUBE_PROX_LL, CUBE_NORMAL_LEFT,
        CUBE_DIST_LL, CUBE_NORMAL_LEFT,
        CUBE_PROX_LR, CUBE_NORMAL_BOTTOM,
        CUBE_DIST_LR, CUBE_NORMAL_BOTTOM
    };
    
    GLfloat *gCubeVertexDataCons = (GLfloat *)malloc(VERTEX_COUNT*sizeof(GLfloat));
    for (int i = 0; i<VERTEX_COUNT; i++)gCubeVertexDataCons[i] = gCubeVertexDataLocal[i];
    return gCubeVertexDataCons;
}

-(GLfloat *)generateCubeWithHeigth:(float)heighti{
    
    float height = (heighti * 2) - 1.0f;
    GLfloat gCubeVertexDataLocal[216] =
    {
        // Data layout for each line below is:
        // positionX, positionY, positionZ, normalX, normalY, normalZ,
        0.5f, -0.5f, -0.5f*height, 1.0f, 0.0f, 0.0f,
        0.5f, 0.5f, -0.5f*height, 1.0f, 0.0f, 0.0f,
        0.5f, -0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
        0.5f, -0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
        0.5f, 0.5f, -0.5f*height, 1.0f, 0.0f, 0.0f,
        0.5f, 0.5f, 0.5f, 1.0f, 0.0f, 0.0f,
        
        0.5f, 0.5f, -0.5f*height, 0.0f, 1.0f, 0.0f,
        -0.5f, 0.5f, -0.5f*height, 0.0f, 1.0f, 0.0f,
        0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
        0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
        -0.5f, 0.5f, -0.5f*height, 0.0f, 1.0f, 0.0f,
        -0.5f, 0.5f, 0.5f, 0.0f, 1.0f, 0.0f,
        
        -0.5f, 0.5f, -0.5f*height, -1.0f, 0.0f, 0.0f,
        -0.5f, -0.5f, -0.5f*height, -1.0f, 0.0f, 0.0f,
        -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
        -0.5f, 0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
        -0.5f, -0.5f, -0.5f*height, -1.0f, 0.0f, 0.0f,
        -0.5f, -0.5f, 0.5f, -1.0f, 0.0f, 0.0f,
        
        -0.5f, -0.5f, -0.5f*height, 0.0f, -1.0f, 0.0f,
        0.5f, -0.5f, -0.5f*height, 0.0f, -1.0f, 0.0f,
        -0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
        -0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
        0.5f, -0.5f, -0.5f*height, 0.0f, -1.0f, 0.0f,
        0.5f, -0.5f, 0.5f, 0.0f, -1.0f, 0.0f,
        
        0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        -0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        -0.5f, 0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        -0.5f, -0.5f, 0.5f, 0.0f, 0.0f, 1.0f,
        
        0.5f, -0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f,
        -0.5f, -0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f,
        0.5f, 0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f,
        0.5f, 0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f,
        -0.5f, -0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f,
        -0.5f, 0.5f, -0.5f*height, 0.0f, 0.0f, -1.0f
    };
    
    GLfloat *gCubeVertexDataCons = (GLfloat *)malloc(216*sizeof(GLfloat));
    for (int i = 0; i<216; i++)gCubeVertexDataCons[i] = gCubeVertexDataLocal[i];
    return gCubeVertexDataCons;
}



-(void)applyRotationWithCGPoint:(CGPoint)diff{
    float rotX = diff.y * 0.005;//-1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = diff.x * 0.005;//-1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
}
-(void)applyRotationWithInternalState{
    [self applyRotationWithCGPoint:rotation];
}

-(void)rotateX:(float)angleX Y:(float)angleY Z:(float)angleZ{
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, angleX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, angleY, yAxis.x, yAxis.y, yAxis.z);
    GLKVector3 zAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible),
                                                 GLKVector3Make(0, 0, 1));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, angleZ, zAxis.x, zAxis.y, zAxis.z);
    [self refresh];
}

-(void)mouseDown:(NSEvent *)theEvent{
    
}

-(BOOL)computeOffSets:(NSEvent *)theEvent{
    float factor = theEvent.deltaY * .002f;
    CGRect rect = [self.delegate rectToRender];
    float minX = rect.origin.x;
    float maxX = rect.origin.x + rect.size.width;
    //NSLog(@"%f %f %@", minX, maxX, NSStringFromRect(rect));
    float minY = rect.origin.y;
    float maxY = rect.origin.y + rect.size.height;
    
    if (theEvent.modifierFlags & NSEventModifierFlagControl) {
        //Init lazily
        
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _rightXOffset = MAX(MIN(1 - minX, _rightXOffset + factor), 1 - maxX);
        else
            _leftXOffset = MAX(MIN(maxX, _leftXOffset + factor), minX);
        return YES;
    }
    if (theEvent.modifierFlags & NSEventModifierFlagOption) {
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _upperYOffset = MAX(MIN(maxY, _upperYOffset + factor), minY);
        else
            _lowerYOffset = MAX(MIN(1 - minY, _lowerYOffset + factor), 1 - maxY);
        NSLog(@"%f %f %f %f %@", minY, maxY, _upperYOffset, _lowerYOffset, NSStringFromRect(rect));
        return YES;
    }
    if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _nearZOffset = MAX(MIN(1.0f, _nearZOffset + factor), .0f);
        else
            _farZOffset = MAX(MIN(1.0f, _farZOffset + factor), .0f);
        return YES;
    }
    return NO;
}
-(BOOL)scrollWithWheel:(NSEvent *)theEvent{
    float factor = theEvent.deltaX * .01f;
    if (theEvent.modifierFlags & NSEventModifierFlagShift){
        if (theEvent.modifierFlags & NSEventModifierFlagControl)
            [self rotateX:factor Y:.0f Z:.0f];
        else if (theEvent.modifierFlags & NSEventModifierFlagControl)
            [self rotateX:.0f Y:factor Z:.0f];
        else if (theEvent.modifierFlags & NSEventModifierFlagControl)
            [self rotateX:.0f Y:.0f Z:factor];
        else
            [self rotateX:factor Y:factor Z:factor];
        return YES;
    }
    return NO;
}

#define MAX_ALLOWED_ZOOM 10.0f
- (void)scrollWheel:(NSEvent *)theEvent {
    if(![self computeOffSets:theEvent]){
        if(![self scrollWithWheel:theEvent]){
            zoom += theEvent.deltaY *0.2;
            if(zoom > MAX_ALLOWED_ZOOM){
                zoom = MAX_ALLOWED_ZOOM;
                return;
            }
            if(zoom < -MAX_ALLOWED_ZOOM){
                zoom = -MAX_ALLOWED_ZOOM;
                return;
            }
        }
    }
    [self refresh];
}


-(void)mouseDragged:(NSEvent *)theEvent{
    if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
        position.x += theEvent.deltaX;
        position.y -= theEvent.deltaY;
    }else{
        rotation.x = theEvent.deltaX;
        rotation.y = theEvent.deltaY;
        [self applyRotationWithCGPoint:rotation];
    }
    [self refresh];
}

-(BOOL)acceptsFirstResponder{
    return YES;
}

-(void)refresh{
    //NSLog(@"The Bounds of the OpenGLView are %@", NSStringFromRect(self.bounds));
    [self drawRect:[self bounds]];
    //[self setNeedsDisplay:YES];
}

-(void)colorComps{
    self.colorsObtained = [self.delegate colors];
    if(colors){
        free(colors);
        colors = NULL;
    }
    colors = (float *)malloc(self.colorsObtained.count * 4 * sizeof(float));
    
    for (int i = 0; i< self.colorsObtained.count; i++) {
        NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
        colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        colors[i*4] = colorObj.redComponent;;
        colors[i*4+1] = colorObj.greenComponent;;
        colors[i*4+2] = colorObj.blueComponent;
    }
    
}

-(void)backGroundColor{
    NSColor *colorBckg = [[self.delegate backgroundColor]colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    glClearColor(colorBckg.redComponent, colorBckg.greenComponent, colorBckg.blueComponent, 1.0f);
}

-(NSUInteger *)cIndexArrayFromIndexSet:(NSIndexSet *)indexSet{
    NSUInteger * cBaseIndexes = malloc(indexSet.count * sizeof(NSUInteger));
    
    __block int cursor = 0;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        cBaseIndexes[cursor] = index;
        cursor++;
    }];
    return cBaseIndexes;
}
-(NSUInteger *)cIndexArrayFromArray:(NSArray *)indexSetArray{
    NSUInteger * cBaseIndexes = malloc(indexSetArray.count * sizeof(NSUInteger));
    for (NSNumber *num in indexSetArray) {
        cBaseIndexes[[indexSetArray indexOfObject:num]] = num.integerValue;
    }
    return cBaseIndexes;
}

/*-(BOOL)checkNeedsUpdate{
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
    
    if(bufferDataLayers != bufferDataLayersLoaded)
        update = YES;
    
    if(update == YES){
        self.colorsObtained = currentColors;
        self.indexesObtained = currentIndexes;
    }
    
    return update;
}

-(void)bufferData{
    [self cleanBuffer];
    bufferDataLayersLoaded = 0;
    
    float *** data = [self.delegate threeDData];
    float *zValues = [self.delegate zValues];
    
    if(!self.delegate)
        return;
    if([self.delegate numberOfChannels] < 1)
        return;
    if([self.delegate numberOfChannels] < 1)
        return;
    if(data == NULL)
        return;
    if(zValues == NULL)
        return;
    
    NSIndexSet *indexesStacks = [self.delegate stacksIndexSet];
    NSInteger indexesStacksCount = indexesStacks.count;
    bufferDataLayers = (int)indexesStacksCount;
    
    NSInteger widthModel = (float)[self.delegate witdhModel];
    NSInteger heightModel = (float)[self.delegate heightModel];
    NSInteger totalPixels = widthModel * heightModel;
        
    if(totalPixels < 1)
        return;
    
    bufferedData = malloc(bufferDataLayers * sizeof(float *));
    for (int i = 0; i < bufferDataLayers; i++) {
        bufferedData[i] = calloc(totalPixels, sizeof(float) * 7);//r, g, b, aux, x, y, z
    }
    
    bool *mask = [self.delegate showMask];
    
    NSInteger leftX = _leftXOffset * widthModel;
    NSInteger rightX = (1 - _rightXOffset) * widthModel;
    NSInteger upperY = _upperYOffset * heightModel;
    NSInteger lowerY = (1 - _lowerYOffset) * heightModel;
    
    
    [self colorComps];

    //CGRect rectToRender = [self.delegate rectToRender];//TODO
    
    float *thicknesses = [self.delegate thicknesses];
    float totalThickness = [self.delegate totalThickness];
    
    
    NSInteger firstPix = _upperYOffset * widthModel;
    NSInteger lastPix = totalPixels - _lowerYOffset * widthModel;
    

    
    //Prepare C Arrays of indexes
    NSArray *indexesChannels = [self.delegate inOrderIndexes];
    NSInteger indexChannelsCount = indexesChannels.count;
    NSUInteger * cBaseIndexesChannels = [self cIndexArrayFromArray:indexesChannels];
    NSUInteger * cBaseIndexesStacks = [self cIndexArrayFromIndexSet:indexesStacks];
    
    [self prepareVertexBuffer];
    
    float dataVal = .0f;
    float allColors = .0f;
    NSInteger chann;

    float red = .0f, green = .0f, blue = .0f;//Blend colors here
    
    float z = .0f;
    
    for (NSInteger stack = 0; stack < bufferDataLayers; stack++) {
        
        int x = 0;
        int y = 0;
        
        NSUInteger indexOfStack = cBaseIndexesStacks[stack];
        
        z = -zValues[indexOfStack] + totalThickness/2;
        float oldThickness = self.defaultThickness;
        self.defaultThickness = thicknesses[indexOfStack];
        if(oldThickness != self.defaultThickness)
            [self prepareVertexBuffer];//Gotta change voxels every stack, as thickness could vary. Normally 2uM though
        
        float **stackData = data[indexOfStack];
        
        if(stackData == NULL)
            continue;
        
        float *stackChannelData = NULL;
        
        
        for (NSInteger i = firstPix; i < lastPix; i++) {
            
            if(mask[i] == true && x >= leftX && x <= rightX && y >= upperY && y <= lowerY){
                
                NSUInteger indexOfStack = cBaseIndexesStacks[stack];
                
                float oldThickness = self.defaultThickness;
                self.defaultThickness = thicknesses[indexOfStack];
                if(oldThickness != self.defaultThickness)
                    [self prepareVertexBuffer];//Gotta change voxels every stack, as thickness could vary. Normally 2uM though
                
                red = .0f, green = .0f, blue = .0f;
                
                for (chann = 0; chann < indexChannelsCount; chann++) {
                    
                    stackChannelData = stackData[cBaseIndexesChannels[chann]];
                    if(!stackChannelData)
                        continue;
                    
                    NSInteger premult = chann * 4;
                    dataVal = stackChannelData[i];
                    
                    if(dataVal > .0f){
                        red += dataVal * colors[premult];
                        green += dataVal * colors[premult + 1];
                        blue += dataVal * colors[premult + 2];
                    }
                    if(red > 1.0f)red = 1.0f;
                    if(green > 1.0f)green = 1.0f;
                    if(blue > 1.0f)blue = 1.0f;
                    
                    allColors = MAX(red, MAX(green, blue));
                    
                    bufferedData[stack][i * 7] = red;
                    bufferedData[stack][i * 7 + 1] = green;
                    bufferedData[stack][i * 7 + 2] = blue;
                    bufferedData[stack][i * 7 + 3] = allColors;
                    bufferedData[stack][i * 7 + 4] = x;
                    bufferedData[stack][i * 7 + 5] = y;
                    bufferedData[stack][i * 7 + 6] = z;
                    
                }
            }
            x++;
            if(x == widthModel)
            {
                x = 0;
                y++;
            }
        }
        bufferDataLayersLoaded++;
    }
    free(cBaseIndexesStacks);
    free(cBaseIndexesChannels);
}
-(void)drawRect:(NSRect)dirtyRect{
    
    //[super drawRect:dirtyRect];
    
    if(working)
        return;
    working = YES;
    
    if([self checkNeedsUpdate])
        [self bufferData];
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self backGroundColor];
    
    //Get from delegate all necessary data
    bool *mask = [self.delegate showMask];
    
    NSInteger widthModel = (float)[self.delegate witdhModel];
    NSInteger heightModel = (float)[self.delegate heightModel];
    NSInteger totalPixels = widthModel * heightModel;
    NSInteger leftX = _leftXOffset * widthModel;
    NSInteger rightX = (1 - _rightXOffset) * widthModel;
    NSInteger upperY = _upperYOffset * heightModel;
    NSInteger lowerY = (1 - _lowerYOffset) * heightModel;
    
    float combinedAlpha = [self.delegate combinedAlpha];
    AlphaMode alphaMode = [self.delegate alphaMode];
    [self colorComps];
    int coloring = [self.delegate coloringType];
    //CGRect rectToRender = [self.delegate rectToRender];//TODO
    float *zValues = [self.delegate zValues];
    float *thicknesses = [self.delegate thicknesses];
    NSPoint centerOffsets = [self.delegate centerInterestArea];
    
    NSInteger firstPix = _upperYOffset * widthModel;
    NSInteger lastPix = totalPixels - _lowerYOffset * widthModel;
    
    NSPoint centralPosition = NSMakePoint(-(widthModel/2) - centerOffsets.x, (heightModel/2) + centerOffsets.y);
    
    if(self.delegate && [self.delegate numberOfChannels] > 0 && [self.delegate numberOfStacks] > 0 && totalPixels > 0 && bufferedData != NULL && zValues != NULL){
        
        //General positioning
        GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(position.x, position.y, -1000.0f + MIN(1000, MAX(zoom * 100, 0)));
        
        //Init colors
        self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
        //if(coloring == COLORING_TYPE_DIFFUSE_EMISSIVE)
        //    self.effect.material.emissiveColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
        //else self.effect.light0.diffuseColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
        
        
        //Prepare C Arrays of indexes

        NSIndexSet *indexesStacks = [self.delegate stacksIndexSet];
        NSInteger indexesStacksCount = indexesStacks.count;
        NSUInteger * cBaseIndexesStacks = [self cIndexArrayFromIndexSet:indexesStacks];
        
        [self prepareVertexBuffer];
        
        
        for (NSInteger stack = 0; stack < indexesStacksCount; stack++) {
        
            NSUInteger indexOfStack = cBaseIndexesStacks[stack];
            
            float oldThickness = self.defaultThickness;
            self.defaultThickness = thicknesses[indexOfStack];
            if(oldThickness != self.defaultThickness)
                [self prepareVertexBuffer];//Gotta change voxels every stack, as thickness could vary. Normally 2uM though
            
            float *stackData = bufferedData[indexOfStack];
            
            if(stackData == NULL)
                continue;
            
            GLKVector4 color;
            
            for (NSInteger i = firstPix; i < lastPix; i++) {
                
                if(mask[i] == true){
                    
                    float *data = (float *)&stackData[i * 7];
                 
                    if((NSInteger)data[4] < leftX && (NSInteger)data[4] > rightX && (NSInteger)data[5] < upperY && (NSInteger)data[5] > lowerY)
                        continue;
                    
                    switch (alphaMode) {
                        case ALPHA_MODE_OPAQUE:
                            color = GLKVector4Make(data[0], data[1], data[2], 1.0f);
                            break;
                        case ALPHA_MODE_FIXED:
                            color = GLKVector4Make(data[0], data[1], data[2], combinedAlpha);
                            break;
                        case ALPHA_MODE_ADAPTIVE:
                            color = GLKVector4Make(data[0], data[1], data[2], MIN(1.0f, data[3]));
                            break;
                        default:
                            color = GLKVector4Make(data[0], data[1], data[2], .5f);
                            break;
                    }
                    
                    if(data[3] > combinedAlpha){
                        
                        NSPoint cursorPosition = NSMakePoint(centralPosition.x + data[4], centralPosition.y - data[5]);
                        if(coloring == COLORING_TYPE_DIFFUSE_LIGHT_0)
                            self.effect.material.diffuseColor = color;
                        else
                            self.effect.material.emissiveColor = color;
                        
                        GLKMatrix4 modelV = GLKMatrix4Translate(_rotMatrix,
                                                                cursorPosition.x,
                                                                cursorPosition.y,
                                                                data[6]);
                        
                        modelV = GLKMatrix4Multiply(baseModelViewMatrix, modelV);
                        self.effect.transform.modelviewMatrix = modelV;
                        
                        [self.effect prepareToDraw];
                        glDrawArrays(GL_TRIANGLES, 0, 36);
                    }
                }
            }
        }
        free(cBaseIndexesStacks);
    }
    
    [[self openGLContext] flushBuffer];
    
    if([[self.delegate legends]state] == NSOnState)
        [self addLabelsOverlayed];
    
    working = NO;
}*/


-(void)drawRect:(NSRect)dirtyRect{
    
    [super drawRect:dirtyRect];
    
    if(working)
        return;
    working = YES;
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self backGroundColor];
    
    //Get from delegate all necessary data
    float *** data = [self.delegate threeDData];
    bool *mask = [self.delegate showMask];
    
    NSInteger widthModel = (float)[self.delegate witdhModel];
    NSInteger heightModel = (float)[self.delegate heightModel];
    NSInteger totalPixels = widthModel * heightModel;
    NSInteger leftX = _leftXOffset * widthModel;
    NSInteger rightX = (1 - _rightXOffset) * widthModel;
    NSInteger upperY = _upperYOffset * heightModel;
    NSInteger lowerY = (1 - _lowerYOffset) * heightModel;
    
    NSLog(@"U %li L %li %f %f", upperY, lowerY, _upperYOffset, _lowerYOffset);
    
    float combinedAlpha = [self.delegate combinedAlpha];
    AlphaMode alphaMode = [self.delegate alphaMode];
    [self colorComps];
    int coloring = [self.delegate coloringType];
    float *zValues = [self.delegate zValues];
    float *thicknesses = [self.delegate thicknesses];
    NSPoint centerOffsets = [self.delegate centerInterestArea];
    float totalThickness = [self.delegate totalThickness];
    
    
    NSInteger firstPix = floorf(_upperYOffset) * widthModel;//TODO improve
    NSInteger lastPix = totalPixels - _lowerYOffset * widthModel;
    
    NSPoint centralPosition = NSMakePoint(-(widthModel/2) - centerOffsets.x, (heightModel/2) + centerOffsets.y);
    
    
    if(self.delegate && [self.delegate numberOfChannels] > 0 && [self.delegate numberOfStacks] > 0 && totalPixels > 0 && data != NULL && zValues != NULL){
        
        //General positioning
        GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(position.x, position.y, -1000.0f + MIN(1000, MAX(zoom * 100, 0)));
        
        //Init colors
        self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
        //if(coloring == COLORING_TYPE_DIFFUSE_EMISSIVE)
        //    self.effect.material.emissiveColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
        //else self.effect.light0.diffuseColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);

        
        //Prepare C Arrays of indexes
        NSArray *indexesChannels = [self.delegate inOrderIndexes];
        NSInteger indexChannelsCount = indexesChannels.count;
        NSUInteger * cBaseIndexesChannels = [self cIndexArrayFromArray:indexesChannels];
        NSIndexSet *indexesStacks = [self.delegate stacksIndexSet];
        NSInteger indexesStacksCount = indexesStacks.count;
        NSUInteger * cBaseIndexesStacks = [self cIndexArrayFromIndexSet:indexesStacks];
        
        [self prepareVertexBuffer];
    
        float dataVal = .0f;
        float allColors = .0f;
        NSInteger chann;
        float red = .0f, green = .0f, blue = .0f;//Blend colors here
        
        float z = .0f;
        
        for (NSInteger stack = 0; stack < indexesStacksCount; stack++) {
            
            int x = 0;
            int y = 0;
            
            NSUInteger indexOfStack = cBaseIndexesStacks[stack];
            
            z = -zValues[indexOfStack] + totalThickness/2;
            float oldThickness = self.defaultThickness;
            self.defaultThickness = thicknesses[indexOfStack];
            if(oldThickness != self.defaultThickness)
                [self prepareVertexBuffer];//Gotta change voxels every stack, as thickness could vary. Normally 2uM though
            
            float **stackData = data[indexOfStack];

            if(stackData == NULL)
                continue;
            
            float *stackChannelData = NULL;
            
            GLKVector4 color;
            
            for (NSInteger i = firstPix; i < lastPix; i++) {
                
                if(mask[i] == true && x >= leftX && x <= rightX && y >= upperY && y <= lowerY){
                    
                    red = .0f, green = .0f, blue = .0f;
                    
                    for (chann = 0; chann < indexChannelsCount; chann++) {
                        
                        stackChannelData = stackData[cBaseIndexesChannels[chann]];
                        if(!stackChannelData)
                            continue;
                        
                        NSInteger premult = chann * 4;
                        dataVal = stackChannelData[i];
                        
                        if(dataVal > .0f){
                            red += dataVal * colors[premult];
                            green += dataVal * colors[premult + 1];
                            blue += dataVal * colors[premult + 2];
                        }
                    }
                    
                    if(red > 1.0f)red = 1.0f;
                    if(green > 1.0f)green = 1.0f;
                    if(blue > 1.0f)blue = 1.0f;
                    if(red < combinedAlpha)red = .0f;
                    if(green < combinedAlpha)green = .0f;
                    if(blue < combinedAlpha)blue = .0f;
                    
                    allColors = MAX(red, MAX(green, blue));
                    
                    switch (alphaMode) {
                        case ALPHA_MODE_OPAQUE:
                            color = GLKVector4Make(red, green, blue, 1.0f);
                            break;
                        case ALPHA_MODE_FIXED:
                            color = GLKVector4Make(red, green, blue, combinedAlpha);
                            break;
                        case ALPHA_MODE_ADAPTIVE:
                            color = GLKVector4Make(red, green, blue, MIN(1.0f, allColors));
                            break;
                        default:
                            color = GLKVector4Make(red, green, blue, .5f);
                            break;
                    }
                    
                    if(allColors > combinedAlpha){
                        
                        NSPoint cursorPosition = NSMakePoint(centralPosition.x + x, centralPosition.y - y);
                        if(coloring == COLORING_TYPE_DIFFUSE_LIGHT_0)
                            self.effect.material.diffuseColor = color;
                        else
                            self.effect.material.emissiveColor = color;
                        
                        GLKMatrix4 modelV = GLKMatrix4Translate(_rotMatrix,
                                                                cursorPosition.x,
                                                                cursorPosition.y,
                                                                z);
                        
                        modelV = GLKMatrix4Multiply(baseModelViewMatrix, modelV);
                        self.effect.transform.modelviewMatrix = modelV;
                        
                        [self.effect prepareToDraw];
                        glDrawArrays(GL_TRIANGLES, 0, 36);
                    }
                }
                x++;
                if(x == widthModel)
                {
                    x = 0;
                    y++;
                }
            }
        }
        free(cBaseIndexesStacks);
        free(cBaseIndexesChannels);
    }
    
    if([[self.delegate legends]state] == NSOnState)
        [self addLabelsOverlayed];
    
    [[self openGLContext] flushBuffer];
    
    working = NO;
}

-(void)addLabelsOverlayed{
    
    for (NSView *aV in self.subviews.copy)
        [aV removeFromSuperview];
    
    NSArray *colorsObtained = [self.delegate colors];
    NSArray *channsObtained = [self.delegate channelsForCell];
    CGFloat width = self.bounds.size.width;
    CGFloat heigthLabel = 30;
    if(colorsObtained.count == channsObtained.count){
        for (NSString *chann in channsObtained) {
            NSInteger index = [channsObtained indexOfObject:chann];
            NSTextField *field = [[NSTextField alloc]initWithFrame:NSMakeRect(10.0f, heigthLabel * index, width, heigthLabel)];
            field.textColor = [colorsObtained objectAtIndex:index];
            field.backgroundColor = [NSColor clearColor];
            field.font = [NSFont systemFontOfSize:25.0f];
            field.bordered = NO;
            [field setStringValue:chann];
            [self addSubview:field];
        }
    }
}

-(void)addALabel{
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:100 pixelsHigh:30
                                                                    bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bitmapFormat:0 bytesPerRow:100 bitsPerPixel:8];
    
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    
    
    NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:@"firstsecondthird"];
    [string addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(0,5)];
    [string addAttribute:NSForegroundColorAttributeName value:[NSColor greenColor] range:NSMakeRange(5,6)];
    [string addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(11,5)];
    
    [string drawAtPoint:NSMakePoint(0, 0)]; // draw at offset position
    
    
    [NSGraphicsContext restoreGraphicsState];
    
    if (0 == texName)
        glGenTextures (1, &texName);
    
    glBindTexture (GL_TEXTURE, texName);
    
    glTexSubImage2D(GL_TEXTURE_RECTANGLE, 0, 0, 0, 100, 30, GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
}

#pragma mark get image

#pragma mark clean up

-(void)cleanBuffer{
    if(bufferedData){
        for (int i = 0; i < bufferDataLayers; i++) {
            if(bufferedData[i])
                free(bufferedData[i]);
        }
        free(bufferedData);
    }
}

-(void)dealloc{
    [self cleanBuffer];
}
@end
