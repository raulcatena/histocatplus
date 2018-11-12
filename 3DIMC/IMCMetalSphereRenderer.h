//
//  IMCMetalSphereRenderer.h
//  3DIMC
//
//  Created by Raul Catena on 11/18/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalViewAndRenderer.h"
#import "IMC3DMask.h"
#import <MetalKit/MetalKit.h>
#import "OpenGLView.h"
#import "IMCMtkView.h"

@class IMC3DMask;

@interface IMCMetalSphereRenderer : IMCMetalViewAndRenderer

@property (nonatomic, strong) IMC3DMask *computation;
@property (nonatomic, assign) NSInteger cellsToRender;
@property (nonatomic, assign) NSInteger stripes;

-(instancetype)initWith3DMask:(IMC3DMask *)mask3D;
-(void)addSphereVertexBuffer;

@end
