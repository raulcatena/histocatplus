//
//  IMCChannelOperations.h
//  3DIMC
//
//  Created by Raul Catena on 1/29/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCFileWrapper;
@class IMCImageStack;
@class IMCComputationOnMask;

typedef enum{
    OPERATION_REMOVE_CHANNELS,
    OPERATION_ADD_CHANNELS,
    OPERATION_MULTIPLY_CHANNELS
}kOperation;

@interface IMCChannelOperations : NSObject

+(BOOL)operationOnImages:(NSArray <IMCImageStack *>*)images operation:(kOperation)operation withIndexSetChannels:(NSIndexSet *)indexSet toIndex:(NSInteger)index block:(void(^)())block;
+(void)applySettingsFromStack:(IMCImageStack *)stack stacks:(NSArray <IMCImageStack *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)())block;
+(void)applySettingsAdjustToMaxFromStack:(IMCImageStack *)stack stacks:(NSArray <IMCImageStack *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)())block;
+(void)applySettingsFromComputation:(IMCComputationOnMask *)computation stacks:(NSArray <IMCComputationOnMask *>*)computations withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)())block;
+(void)applyColors:(IMCImageStack *)stack stacks:(NSArray <IMCFileWrapper *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)())block;

//On computations
+(BOOL)operationOnComputations:(NSArray <IMCComputationOnMask *>*)comps operation:(kOperation)operation withIndexSetChannels:(NSIndexSet *)indexSet toIndex:(NSInteger)index block:(void(^)())block;

//File saving
+(void)savefiles:(NSArray <IMCFileWrapper *>*)files block:(void(^)())block;
+(void)converttoTIFFFiles:(NSArray <IMCFileWrapper *>*)files block:(void(^)())block;

//Change Channels
+(void)changeChannelsToStacks:(NSArray *)stacks withFile:(NSURL *)url block:(void(^)())block;

@end
