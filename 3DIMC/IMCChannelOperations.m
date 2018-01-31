//
//  IMCChannelOperations.m
//  3DIMC
//
//  Created by Raul Catena on 1/29/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCChannelOperations.h"
#import "IMCImageStack.h"
#import "IMCComputationOnMask.h"
#import "IMCPixelClassification.h"
#import "IMCFileWrapper.h"
#import "IMCPanoramaWrapper.h"

@implementation IMCChannelOperations

+(void)savefiles:(NSArray <IMCFileWrapper *>*)files block:(void(^)(void))block{
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCFileWrapper *file in files){
            [file save];
        }
        
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

+(void)changeChannelsToStacks:(NSArray *)stacks withFile:(NSURL *)url block:(void(^)(void))block{
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        NSString *str = [[NSString alloc]initWithData:[NSData dataWithContentsOfFile:url.path] encoding:NSUTF8StringEncoding];
        NSArray *arr = [str componentsSeparatedByString:@"\t"];NSLog(@"%@", arr);
        if(arr.count > 1)
        for (IMCImageStack *stack in stacks){
            NSInteger preLength = stack.channels.count;
            [stack.channels replaceObjectsAtIndexes:
                                [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, MIN(preLength, arr.count))]
                            withObjects:[arr subarrayWithRange:NSMakeRange(0, MIN(preLength, arr.count))]
             ];
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

+(BOOL)operationOnImages:(NSArray <IMCImageStack *>*)images operation:(kOperation)operation withIndexSetChannels:(NSIndexSet *)indexSet toIndex:(NSInteger)index block:(void(^)(void))block{
    if(images.count == 0)
        return NO;
    NSInteger sure = [General runAlertModalAreYouSure];
    if (sure == NSAlertSecondButtonReturn)
        return NO;
    
    NSMutableArray *closedFiles = @[].mutableCopy;
    for (IMCImageStack *stack in images)
        if(!stack.fileWrapper.isLoaded)
            if(![closedFiles containsObject:stack.fileWrapper])
                [closedFiles addObject:stack.fileWrapper];
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCImageStack *stack in images) {
            
            if(!stack.fileWrapper.isLoaded)
                [stack.fileWrapper loadLayerDataWithBlock:nil];
            while(!stack.fileWrapper.isLoaded);
            
            switch (operation) {
                case OPERATION_REMOVE_CHANNELS:
                    [stack removeChannelsWithIndexSet:indexSet];
                    break;
                case OPERATION_ADD_CHANNELS:
                    [stack addChannelsWithIndexSet:indexSet toInlineIndex:index];
                    break;
                case OPERATION_MULTIPLY_CHANNELS:
                    [stack multiplyChannelsWithIndexSet:indexSet toInlineIndex:index];
                    break;
                    
                default:
                    break;
            }
            [stack.fileWrapper saveTIFFAtPath:[stack.fileWrapper backStoreTIFFPath]];
            if([closedFiles containsObject:stack.fileWrapper]){
                [stack.fileWrapper unLoadLayerDataWithBlock:nil];
                [closedFiles removeObject:stack.fileWrapper];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [images.firstObject.fileWrapper.coordinator.delegate saveActionFromCoordinator];
        });
        if(block)
            dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
    return YES;
}

+(BOOL)operationOnComputations:(NSArray <IMCComputationOnMask *>*)comps operation:(kOperation)operation withIndexSetChannels:(NSIndexSet *)indexSet toIndex:(NSInteger)index block:(void(^)(void))block{
    if(comps.count == 0)
        return NO;
    
    NSInteger sure = [General runAlertModalAreYouSure];
    if (sure == NSAlertSecondButtonReturn)
        return NO;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCComputationOnMask *comp in comps) {
            
            BOOL maskWasLoaded = comp.mask.isLoaded;
            if([comp isMemberOfClass:[IMCComputationOnMask class]]){
                if(!maskWasLoaded)
                    [comp.mask loadLayerDataWithBlock:nil];
                while(!comp.mask.isLoaded);
            }
            [comp openIfNecessaryAndPerformBlock:^{
                switch (operation) {
                    case OPERATION_REMOVE_CHANNELS:
                        [comp removeChannelsWithIndexSet:indexSet];
                        break;
                    case OPERATION_ADD_CHANNELS:
                        [comp addChannelsWithIndexSet:indexSet toInlineIndex:index];
                        break;
                    case OPERATION_MULTIPLY_CHANNELS:
                        [comp multiplyChannelsWithIndexSet:indexSet toInlineIndex:index];
                        break;
                        
                    default:
                        break;
                }
            }];
            if(!maskWasLoaded)
                [comp.mask unLoadLayerDataWithBlock:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [comps.firstObject.fileWrapper.coordinator.delegate saveActionFromCoordinator];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block)block();//Don't know why always crashes if I do it in the main thread. It should not, and I usually call refresh in this block. I leave it like this as it fixes the bug but am not convinced
        });
    });
    return YES;
}

+(void)applySettingsFromStack:(IMCImageStack *)stack stacks:(NSArray <IMCFileWrapper *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)(void))block{
    
    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCImageStack *otherStack in stacks) {
            //Check the file has been loaded at least once

            if(otherStack == stack)continue;
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                if(otherStack.channelSettings.count > idx)
                    [otherStack.channelSettings replaceObjectAtIndex:idx withObject:[stack.channelSettings[idx]mutableCopy]];
            }];
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

+(void)applySettingsFromComputation:(IMCComputationOnMask *)computation stacks:(NSArray <IMCComputationOnMask *>*)computations withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)(void))block{
    
    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCComputationOnMask *comp in computations) {
            //Check the file has been loaded at least once
            
            if(comp == computation)continue;
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                if(comp.channelSettings.count > idx)
                    [comp.channelSettings replaceObjectAtIndex:idx withObject:[computation.channelSettings[idx]mutableCopy]];
            }];
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

+(void)applyColors:(IMCImageStack *)stack stacks:(NSArray <IMCFileWrapper *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)(void))block{
    
    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCImageStack *otherStack in stacks) {
            //Check the file has been loaded at least once
            
            if(otherStack == stack)continue;
            
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                if(otherStack.channelSettings.count > idx)
                    otherStack.channelSettings[idx][JSON_DICT_CHANNEL_SETTINGS_COLOR] = stack.channelSettings[idx][JSON_DICT_CHANNEL_SETTINGS_COLOR];
            }];
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

+(void)applySettingsAdjustToMaxFromStack:(IMCImageStack *)stack stacks:(NSArray <IMCImageStack *>*)stacks withIndexSetChannels:(NSIndexSet *)indexSet block:(void(^)(void))block{
    
    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCImageStack *otherStack in stacks) {
            if(otherStack != stack){
                [otherStack openIfNecessaryAndPerformBlock:^{
                    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                        float maxStack = [stack.channelSettings[idx][JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET]floatValue];
                        float maxValue = [stack maxForIndex:idx];
                        
                        if(otherStack.channels.count > idx){
                            float otherMax = [otherStack maxForIndex:idx];
                            float otherAdjust = maxValue * maxStack / otherMax;
                            
                            [otherStack.channelSettings replaceObjectAtIndex:idx withObject:[stack.channelSettings[idx]mutableCopy]];
                            [otherStack.channelSettings[idx] setValue:[NSNumber numberWithFloat:MIN(1.0f, otherAdjust)] forKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET];
                        }
                    }];
                }];
            }
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
    
//    NSMutableArray *closedFiles = @[].mutableCopy;
//    for (IMCImageStack *stack in stacks)
//        if(!stack.fileWrapper.isLoaded)
//            if(![closedFiles containsObject:stack.fileWrapper])
//                [closedFiles addObject:stack.fileWrapper];
    
//    if(!stack.isLoaded){
//        [General runAlertModalWithMessage:@"Run this function from the stacks filter"];
//        return;
//    }
}

+(void)converttoTIFFFiles:(NSArray <IMCFileWrapper *>*)files block:(void(^)(void))block{
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCFileWrapper *wrapper in files) {
            if([wrapper.fileType hasPrefix:EXTENSION_TIFF_PREFIX] || [wrapper hasTIFFBackstore])continue;//Is already
            BOOL loaded = wrapper.isLoaded;
            if(!wrapper.isLoaded)[wrapper loadLayerDataWithBlock:nil];
            [wrapper saveTIFFAtPath:[wrapper backStoreTIFFPath]];
            if(!loaded)[wrapper unLoadLayerDataWithBlock:nil];
        }
        if(block)dispatch_async(dispatch_get_main_queue(), ^{block();});
    });
}

@end
