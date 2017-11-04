//
//  IMCMtkView.m
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMtkView.h"

@interface IMCMtkView()

@property (nonatomic, assign) matrix_float4x4 modelViewProjectionMatrix;

@property (nonatomic, assign) BOOL working;
@property (nonatomic, assign) float ** bufferedData;
@property (nonatomic, assign) int bufferDataLayers;
@property (nonatomic, assign) int bufferDataLayersLoaded;

@end

@implementation IMCMtkView

-(instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if(self){
        _rotationMatrix = [[Matrix4 alloc]init];
        self.leftXOffset = .0f;
        self.rightXOffset = 1.0f;
        self.lowerYOffset = 1.0f;
        self.upperYOffset = .0f;
        self.nearZOffset = .0f;
        self.farZOffset = 1.0f;
    }
    return self;
}

-(void)applyRotationWithCGPoint:(CGPoint)diff{
    
//    float rotX = diff.y * 0.005;
//    float rotY = diff.x * 0.005;
//
//    [self rotateX:rotX Y:0 Z:0];
//    [self rotateX:0 Y:rotY Z:0];
    
    float rotX = diff.y * 0.005;//-1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = diff.x * 0.005;//-1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    [self rotateX:rotX Y:rotY Z:.0f];
    
}
                                                        
-(void)applyRotationWithInternalState{
    [self applyRotationWithCGPoint:_rotation];
}

-(void)rotateX:(float)angleX Y:(float)angleY Z:(float)angleZ{
//    [self.rotationMatrix rotateAroundX:angleX y:angleY z:angleZ];
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(self.rotationMatrix->glkMatrix, &isInvertible),
                                                 GLKVector3Make(1, 0, 0));
    self.rotationMatrix->glkMatrix = GLKMatrix4Rotate(self.rotationMatrix->glkMatrix, angleX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(self.rotationMatrix->glkMatrix, &isInvertible),
                                                 GLKVector3Make(0, 1, 0));
    self.rotationMatrix->glkMatrix = GLKMatrix4Rotate(self.rotationMatrix->glkMatrix, angleY, yAxis.x, yAxis.y, yAxis.z);
    GLKVector3 zAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(self.rotationMatrix->glkMatrix, &isInvertible),
                                                 GLKVector3Make(0, 0, 1));
    self.rotationMatrix->glkMatrix = GLKMatrix4Rotate(self.rotationMatrix->glkMatrix, angleZ, zAxis.x, zAxis.y, zAxis.z);
}

-(void)mouseDragged:(NSEvent *)theEvent{
    
    if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
        [self.baseModelMatrix translate:theEvent.deltaX y:-theEvent.deltaY z:0];
    }else{
        _rotation.x = theEvent.deltaX;
        _rotation.y = theEvent.deltaY;
        [self applyRotationWithCGPoint:_rotation];
    }
    self.refresh = YES;
}

-(BOOL)computeOffSets:(NSEvent *)theEvent{
    float factor = theEvent.deltaY * .002f;
    
    if (theEvent.modifierFlags & NSEventModifierFlagControl) {
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _rightXOffset = MIN(MAX(_leftXOffset, _rightXOffset - factor), 1.0f);
        else
            _leftXOffset = MAX(.0f, MIN(_leftXOffset + factor, _rightXOffset));
        return YES;
    }
    if (theEvent.modifierFlags & NSEventModifierFlagOption) {
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _lowerYOffset = MIN(MAX(_lowerYOffset - factor, _upperYOffset), 1.0f);
        else
            _upperYOffset = MAX(MIN(_upperYOffset + factor, _lowerYOffset), .0f);
        return YES;
    }
    if (theEvent.modifierFlags & NSEventModifierFlagCommand) {
        if (theEvent.modifierFlags & NSEventModifierFlagFunction)
            _nearZOffset = MAX(MIN(_nearZOffset + factor * 3, _farZOffset), .0f);
        else
            _farZOffset = MIN(MAX(_farZOffset - factor * 3, _nearZOffset), 1.0f);
        return YES;
    }
    return NO;
}

#define MAX_ALLOWED_ZOOM 1.0f
- (void)scrollWheel:(NSEvent *)theEvent {
    
    if(![self computeOffSets:theEvent]){
        if(![self scrollWithWheel:theEvent]){
            float value = theEvent.deltaY * 5.0f;
            _zoom += value;
            _zoom = MIN(MAX_ALLOWED_ZOOM, MAX(-MAX_ALLOWED_ZOOM, _zoom));
            if(_zoom > MAX_ALLOWED_ZOOM){
                _zoom = MAX_ALLOWED_ZOOM;
                return;
            }
            if(_zoom < -MAX_ALLOWED_ZOOM){
                _zoom = -MAX_ALLOWED_ZOOM;
                return;
            }
            [self.baseModelMatrix translate:0 y:0 z:value];
        }
    }
    self.refresh = YES;
}
-(BOOL)scrollWithWheel:(NSEvent *)theEvent{
    float factor = theEvent.deltaX * .05f;
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

-(Matrix4 *)baseModelMatrix{
    if(!_baseModelMatrix){
        _baseModelMatrix = [[Matrix4 alloc]init];
        [_baseModelMatrix translate:0 y:0 z:-500];
    }
    return _baseModelMatrix;
}
-(Matrix4 *)rotationMatrix{
    if(!_rotationMatrix){
        _rotationMatrix = [[Matrix4 alloc]init];
    }
    return _rotationMatrix;
}

- (void)mouseUp:(NSEvent *)theEvent {
    
    
}

- (BOOL)acceptsFirstResponder {
    
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.delegate drawInMTKView:self];
}

static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
{
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    CVPixelBufferRelease( pixelBuffer );
}
-(CGImageRef)captureImageRef{
    
    self.framebufferOnly = NO;
    
    id<MTLTexture> texture = self.lastRenderedTexture;
    
    NSInteger width = texture.width;
    NSInteger height   = texture.height;
    
    NSInteger rowBytes = width * 4;
    UInt8 * p = malloc(width * height * 4);
    
    [texture getBytes:p bytesPerRow:rowBytes fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];

    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
    NSInteger selftureSize = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, p, selftureSize, ReleaseCVPixelBuffer);
    CGImageRef cgImageRef = CGImageCreate(width, height, 8, 32, rowBytes, pColorSpace, bitmapInfo, provider, nil, YES, kCGRenderingIntentDefault);
    CFRelease(provider);
    //free(p);
    return cgImageRef;
}
-(NSImage *)captureImage{
    
    self.framebufferOnly = NO;
    
    id<MTLTexture> texture = self.lastRenderedTexture;
    
    NSInteger width = texture.width;
    NSInteger height   = texture.height;
    
    NSInteger rowBytes = width * 4;
    UInt8 * p = malloc(width * height * 4);
    
    [texture getBytes:p bytesPerRow:rowBytes fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
    
    CGColorSpaceRef pColorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
    NSInteger selftureSize = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(nil, p, selftureSize, ReleaseCVPixelBuffer);
    CGImageRef cgImageRef = CGImageCreate(width, height, 8, 32, rowBytes, pColorSpace, bitmapInfo, provider, nil, YES, kCGRenderingIntentDefault);
    NSImage *im = [[NSImage alloc]initWithCGImage:cgImageRef size:NSMakeSize(width, height)];
    CFRelease(provider);
    CGImageRelease(cgImageRef);
    return im;
}
-(void *)captureData{
    
    self.framebufferOnly = NO;
    
    id<MTLTexture> texture = self.lastRenderedTexture;
    
    NSInteger width = texture.width;
    NSInteger height = texture.height;
    
    NSInteger rowBytes = width * 4;
    UInt8 * p = malloc(width * height * 4);
    
    [texture getBytes:p bytesPerRow:rowBytes fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
    return p;
}



@end
