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

@interface IMCMetalViewAndRenderer : NSObject <MTKViewDelegate, Get3DData>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, weak) id<Get3DData> delegate;
@property(nonatomic, assign) BOOL forceColorBufferRecalculation;
@end
