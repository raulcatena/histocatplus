//
//  IMC3DMask.h
//  3DIMC
//
//  Created by Raul Catena on 9/26/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCNodeWrapper.h"

@class IMCLoader;
@class IMC3DHandler;

typedef enum{
    MASK3D_THRESHOLD,
    MASK3D_THRESHOLD_SEGMENT,
    MASK3D_PCML
}Mask3D_Type;

typedef enum{
    MASK3D_VOXELS,
    MASK3D_2D_MASKS
}Mask3D_Origin;

@interface IMC3DMask : IMCNodeWrapper

@property (nonatomic, readonly) NSArray *components;
@property (nonatomic, readonly) NSMutableDictionary *metadata;
@property (nonatomic, readonly) Mask3D_Type type;
@property (nonatomic, readonly) Mask3D_Origin origin;
@property (nonatomic, readonly) NSInteger channel;
@property (nonatomic, readonly) NSInteger substractChannel;
@property (nonatomic, readonly) NSInteger expansion;
@property (nonatomic, readonly) float threshold;
@property (nonatomic, readonly) NSInteger minKernel;
@property (nonatomic, readonly) BOOL sheepShaver;
@property (nonatomic, weak) IMCLoader *coordinator;
@property (nonatomic, weak) IMC3DHandler *threeDHandler;

-(void)setType:(Mask3D_Type)type;
-(void)setOrigin:(Mask3D_Origin)origin;
-(void)setChannel:(NSInteger)channel;
-(void)setSubstractChannel:(NSInteger)substractChannel;
-(void)setExpansion:(NSInteger)expansion;
-(void)setThreshold:(float)threshold;
-(void)setMinKernel:(NSInteger)minKernel;
-(void)setTheComponents:(NSArray *)components;
-(void)setSheepShaver:(BOOL)sheepShaver;

-(instancetype)initWithLoader:(IMCLoader *)loader andHandler:(IMC3DHandler *)handler;

@end