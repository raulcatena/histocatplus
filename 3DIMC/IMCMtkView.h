//
//  IMCMtkView.h
//  3DIMC
//
//  Created by Raul Catena on 9/5/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <MetalKit/MetalKit.h>
#import "Matrix4.h"

@interface IMCMtkView : MTKView
@property (nonatomic, assign) CGFloat zoom;
@property (nonatomic, assign) NSPoint position;
@property (nonatomic, assign) CGPoint rotation;
@property (nonatomic, assign) float *colors;
@property (nonatomic, strong) Matrix4* baseModelMatrix;
@property (nonatomic, strong) Matrix4* rotationMatrix;
@property (nonatomic, assign) float leftX;
@property (nonatomic, assign) float rightX;
@property (nonatomic, assign) float upperY;
@property (nonatomic, assign) float lowerY;
@property (nonatomic, assign) IBInspectable BOOL refresh;
@end
