//
//  IMCPixelClassification.h
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"
#import "IMCImageStack.h"

@class IMCComputationOnMask;

@interface IMCPixelClassification : IMCNodeWrapper

@property (nonatomic, readonly) IMCImageStack *imageStack;

@property (nonatomic, readonly) BOOL isCellMask;
@property (nonatomic, readonly) BOOL isNuclear;
@property (nonatomic, readonly) BOOL isDual;
@property (nonatomic, readonly) BOOL isDesignated;
@property (nonatomic, readonly) NSString *whichMapHash;
@property (nonatomic, readonly) IMCPixelMap *whichMap;
@property (nonatomic, readonly) BOOL isPainted;
@property (nonatomic, readonly) BOOL isThreshold;
@property (nonatomic, readonly) NSMutableDictionary *thresholdSettings;

@property (nonatomic, assign) int * mask;

@property (nonatomic, strong) NSMutableArray<IMCComputationOnMask *> *computationNodes;

-(instancetype)initWithPixelMask:(int *)maskBuffer dictionary:(NSDictionary *)dictionary andParent:(IMCImageStack *)stack;//TODO remove?

-(void)getNuclearMaskAtURL:(NSURL *)url;
-(BOOL)loadMask;
-(BOOL)loadNuclearMask;
-(CGImageRef)coloredMask:(NSInteger)option maskType:(MaskType)maskType singleColor:(NSColor *)color;
-(void)addFeaturesFromCellProfiler:(NSURL *)url;
-(NSInteger)numberOfSegments;
-(void)extractDataForMask:(NSIndexSet *)computations;
-(void)saveFileWith32IntBuffer:(int *)buffer length:(NSInteger)length;
-(void)saveFileWithBuffer:(void *)buffer bits:(size_t)bits;
-(void)initComputations;
-(void)removeChild:(IMCNodeWrapper *)childNode;

@end
