//
//  IMCMtkView.h
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "Matrix4.h"

@interface IMCMtkView : MTKView{

}
@property (nonatomic, assign) CGFloat zoom;
@property (nonatomic, assign) NSPoint position;
@property (nonatomic, assign) CGPoint rotation;
@property (nonatomic, assign) float *colors;
@property (nonatomic, strong) Matrix4* baseModelMatrix;
@property (nonatomic, strong) Matrix4* rotationMatrix;
@property (nonatomic, assign) IBInspectable BOOL refresh;
@property(nonatomic, strong) id<MTLTexture>lastRenderedTexture;

@property (nonatomic, assign) float leftXOffset;
@property (nonatomic, assign) float rightXOffset;
@property (nonatomic, assign) float lowerYOffset;
@property (nonatomic, assign) float upperYOffset;
@property (nonatomic, assign) float nearZOffset;
@property (nonatomic, assign) float farZOffset;

-(void)rotateX:(float)angleX Y:(float)angleY Z:(float)angleZ;

-(CGImageRef)captureImageRef;
-(NSImage *)captureImage;
-(void *)captureData;
-(void)applyRotationWithInternalState;

@end
