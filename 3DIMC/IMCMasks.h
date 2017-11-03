//
//  IMCMasks.h
//  IMCReader
//
//  Created by Raul Catena on 12/10/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;

@interface IMCMasks : NSObject

int * cMaskFromObjectMask(NSArray *mask);
void noBordersMask(int * mask, NSInteger width, NSInteger height);
void bordersOnlyMask(int * mask, NSInteger width, NSInteger height);
+(void)flattenMask:(int *)mask width:(NSInteger)width height:(NSInteger)height;
//+(int *)produceIDedMask:(int *)mask width:(NSInteger)width height:(NSInteger)height;
+(int *)produceIDedMask:(int *)mask width:(NSInteger)width height:(NSInteger)height destroyOrigin:(BOOL)destory;
void transformImageSegmentationResultTo0and255(int * buffer, NSInteger width, NSInteger height);
void increaseMaskBoundsBy(int layer, int *mask, int width, int height);
void increaseMaskBoundsNegBy(int layer, int *mask, int width, int height);
int * copyMask(int *mask, int width, int height);
UInt8 * copyMask8bit(UInt8 *mask, NSInteger width, NSInteger height);
int * createECMMask(int *mask, int width, int height);
int * createWithTheresholMask(int *mask, int width, int height, int threshold);
void invertMask(int *mask, int width, int height);
+(int *)invertMaskCopy:(int *)mask size:(NSInteger)size;
-(NSDictionary *)extractValuesForMask:(int *)mask forChannelData:(int *)channelData width:(int)width height:(int)height channels:(NSArray *)channels;
//Combining masks
//int * extractFromMaskWithMask(int * mask1, int * mask2, int width, int height, float tolerance);
+(int *)extractFromMask:(int *)mask1 withMask:(int *)mask2 width:(NSInteger)width height:(NSInteger)height tolerance:(float)tolerance exclude:(BOOL)exclude filterLabel:(NSInteger)filterLabel;
+(float *)distanceToMasks:(float *)xCentroids yCentroids:(float *)yCentroids  destMask:(int *)maskDestination max:(NSInteger)max width:(NSInteger)width height:(NSInteger)height filterLabel:(NSInteger)filterLabel;
+(void)invertToProximity:(float *)distances cells:(NSInteger)cells;
+(void)idMask:(int *)extracted target:(int *)target size:(CGSize)size;
BOOL doesNotJumpLine(NSInteger index, NSInteger indexTest, NSInteger width, NSInteger height, NSInteger total, NSInteger expectedDistance);
BOOL doesNotJumpLinePlane(NSInteger index, NSInteger indexTest, NSInteger width, NSInteger height, NSInteger totalPlane, NSInteger total, NSInteger expectedDistance);
+(int *)maskFromFile:(NSURL *)url forImageStack:(IMCImageStack *)stack;

@end
