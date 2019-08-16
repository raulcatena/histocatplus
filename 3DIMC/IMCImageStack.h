//
//  IMCImageStack.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"
#import "IMCFileWrapper.h"

@class IMCPixelTraining;
@class IMCPixelMap;
@class IMCPixelClassification;

@interface IMCImageStack : IMCNodeWrapper

@property (nonatomic, assign) float **stackData;
@property (nonatomic, assign) float **compensatedData;
@property (nonatomic, assign) BOOL usingCompensated;
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSMutableArray *channelSettings;
@property (nonatomic, strong) NSMutableDictionary*transform;
@property (nonatomic, strong) NSMutableArray *origChannels;
@property (nonatomic, readonly) NSSize size;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) CGRect rectInPanorama;
@property (nonatomic, readonly) NSUInteger numberOfPixels;
@property (nonatomic, strong) NSString * name;


@property (nonatomic, strong) NSMutableArray<IMCPixelTraining *> *pixelTrainings;
@property (nonatomic, strong) NSMutableArray<IMCPixelMap *> *pixelMaps;
@property (nonatomic, strong) NSMutableArray<IMCPixelClassification *> *pixelMasks;

-(BOOL)hasTIFFBackstore;
-(NSString *)backStoreTIFFPath;
-(void)saveBIMCAtPath:(NSString *)path;
-(void)saveTIFFAtPath:(NSString *)path;

-(void)clearBuffers;
-(void)allocateBuffer;
-(void)allocateBufferWithPixels:(NSUInteger)pixels;
-(void)allocateCacheBufferContainers;
-(NSUInteger)usedBytes;
-(float)maxForIndex:(NSInteger)index;

//Buffers For Indexes
-(UInt8 **)preparePassBuffers:(NSArray *)indexSet;
-(void)removeChannelsWithIndexSet:(NSIndexSet *)indexes;
-(void)addChannelsWithIndexSet:(NSIndexSet *)indexes toInlineIndex:(NSInteger)inLineIndex;
-(void)multiplyChannelsWithIndexSet:(NSIndexSet *)indexes  toInlineIndex:(NSInteger)inLineIndex;

//Helper Color Legend Data
-(NSArray *)maxesForIndexArray:(NSArray *)indexes;
-(NSArray *)maxOffsetsForIndexArray:(NSArray *)indexes;

//Autoadjust
-(void)setAutoMaxForMilenile:(int)milenile andChannel:(NSInteger)channel;

//Get Mask
-(NSDictionary *)getMaskAtURL:(NSURL *)url;

//Remove child
-(void)removeChild:(IMCNodeWrapper *)childNode;

//Channel communication
-(NSInteger)ascertainIndexInStackForComputationChannel:(NSString *)channelName;

//Rotate
-(void)rotate:(float)rotation andTranslate:(float)x y:(float)y;
-(CGAffineTransform)affineTransformSuperCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper;
-(NSInteger *)mapOfIndexesAfterAffineWithSuperCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper;

@end
