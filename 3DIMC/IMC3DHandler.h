//
//  IMC3DHandler.h
//  3DIMC
//
//  Created by Raul Catena on 1/31/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMCImageStack.h"
#import "IMCComputationOnMask.h"
#import "IMCPixelClassification.h"
#import "IMCLoader.h"

@interface IMC3DHandler : NSObject

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) UInt8 *** allBuffer;
@property (nonatomic, assign) bool *showMask;
@property (nonatomic, assign) NSUInteger images;
@property (nonatomic, assign) NSUInteger channels;
@property (nonatomic, assign) NSRect interestProportions;
@property (nonatomic, assign) float defaultZ;
@property (nonatomic, weak) IMCLoader *loader;
@property (nonatomic, readonly) NSArray *indexesArranged;
@property (nonatomic, readonly) NSArray *indexesArranged3DMask;

@property (nonatomic, strong) NSArray *items;


-(void)startBufferForImages:(NSArray *)images channels:(NSInteger)channels width:(NSInteger)width height:(NSInteger)height;
-(void)addImageStackatIndex:(NSInteger)indexStack channel:(NSInteger)channel;
-(void)addComputationAtIndex:(NSInteger)indexStack channel:(NSInteger)channel maskOption:(MaskOption)option maskType:(MaskType)type;
-(void)addMask:(IMCPixelClassification *)mask atIndexOfStack:(NSInteger)indexStack maskOption:(MaskOption)option maskType:(MaskType)type;
-(NSInteger)bytes;
-(float)megabytes;
-(float)gigaBytes;
-(BOOL)isReady;
-(void)allocateMask;
-(NSPoint)proportionalOffsetToCenter;
-(void)prepDeltasAndProportionsWithStacks;
-(float *)zValues;
-(float *)thicknesses;
-(float)totalThickness;
-(void)meanBlurModelWithKernel:(NSInteger)kernel forChannels:(NSIndexSet *)channels mode:(NSInteger)mode;

@end
