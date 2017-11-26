//
//  IMCCell3DTrainerTool.m
//  3DIMC
//
//  Created by Raul Catena on 11/22/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCCell3DTrainerTool.h"
#import "IMC3DMask.h"
#import "IMCImageGenerator.h"

@implementation IMCCell3DTrainerTool

-(IMC3DMask *)mask{
    return (IMC3DMask *)self.trainer.computation;
}
-(NSInteger)maskPlaneLength{
    return [self mask].width * [self mask].height;
}

#pragma mark mask painting
-(void)clickedAtPoint:(NSPoint)point{
    NSPoint processed = [self.scrollView getTranslatedPoint:point];
    
    NSInteger plane = [self mask].width * [self mask].height;
    NSInteger virtualSlice = (NSInteger)([self mask].slices * self.planeSelector.floatValue);

    
    NSInteger pix = MAX(0, MIN(plane - 1, floor(processed.y) * [self mask].width + processed.x));
    
    int cellId = abs([self mask].maskIds[virtualSlice * plane + pix]);
    
    if(cellId > 0 && self.labelsTableView.selectedRow >= 0)
        [self trainingBuff][cellId - 1] = [self trainingBuff][cellId - 1] == 0 ? (int)self.labelsTableView.selectedRow + 1:0;
    
    [self.trainer.trainingNodes.firstObject regenerateDictTraining];
    [self refresh];
}


-(UInt8 *)createImageForClassification{
    
    if(!self.trainer.randomFResults)
        return NULL;
    
    NSInteger size = [self maskPlaneLength];
    NSInteger fullMask = size * [self mask].slices;
    int * copy = (int *)calloc(size, sizeof(int));
    NSInteger virtualSlice = (NSInteger)([self mask].slices * self.planeSelector.floatValue);
    
    NSInteger offSetPlane = virtualSlice * size;
    NSInteger upperLimit = MIN(offSetPlane + size, fullMask);
    for (NSInteger i = offSetPlane, j = 0; i < upperLimit; i++, j++)
        copy[j] = [self mask].maskIds[i];
    
    UInt8 * img = (UInt8 *)calloc(size, sizeof(UInt8));
    if(img == NULL || self.trainer.trainingNodes.firstObject.training == NULL)
        return NULL;
    
    float * learntData = self.trainer.randomFResults;
    float factor = 255.0f/self.trainer.labels.count;
    
    for (NSInteger i = 0; i < size; i++) {
        if(copy[i] == 0)continue;
        NSInteger index = abs(copy[i]) - 1;
        float orValue = learntData[index * (self.trainer.useChannels.count + 1) + self.trainer.useChannels.count];
        int classPredicted = floor(orValue);
        //float prob = orValue - classPredicted;
        int val = classPredicted * (int)factor;
        
        img[i] = val;
        
    }
    free(copy);
    return img;
}
-(UInt8 *)createImageForTraining{
    
    NSInteger size = [self maskPlaneLength];
    NSInteger fullMask = size * [self mask].slices;
    int * copy = (int *)calloc(size, sizeof(int));
    NSInteger virtualSlice = (NSInteger)([self mask].slices * self.planeSelector.floatValue);
    
    //Get slice of 3D mask
    NSInteger offSetPlane = virtualSlice * size;
    NSInteger upperLimit = MIN(offSetPlane + size, fullMask);
    for (NSInteger i = offSetPlane, j = 0; i < upperLimit; i++, j++)
        copy[j] = [self mask].maskIds[i];
    
    UInt8 * img = (UInt8 *)calloc(size, sizeof(UInt8));
    if(img == NULL || self.trainer.trainingNodes.firstObject.training == NULL)
        return NULL;
    
    int * cellData = self.trainer.trainingNodes.firstObject.training;
    float factor = 255.0f/self.trainer.labels.count;
    
    for (NSInteger i = 0; i < size; i++) {
        if(copy[i] == 0)continue;
        NSInteger index = abs(copy[i]) - 1;
        int val = cellData[index] * (int)factor;
        img[i] = val;
    }
    
    free(copy);
    return img;
}
-(void)addUint8Buffer:(UInt8 *)buffer toStack:(NSMutableArray *)stackRefs direction:(BOOL)clockWise{
    
    CGImageRef refi = [IMCImageGenerator imageFromCArrayOfValues:buffer color:nil width:[self mask].width height:[self mask].height startingHueScale:0 hueAmplitude:255 direction:clockWise ecuatorial:NO brightField:NO];
    
    const CGFloat myMaskingColors[6] = { 0, 100, 0, 100, 0, 100 };
    CGImageRef masked = CGImageCreateWithMaskingColors (refi, myMaskingColors);
    
    if(masked)
        [stackRefs addObject:(__bridge id)masked];
    if(refi)
        CFRelease(refi);
    
    if(buffer)
        free(buffer);
}
-(void)refresh{
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:self.channelTableView.selectedRowIndexes.count];
    for (int i = 0; i < self.channelTableView.selectedRowIndexes.count; i++) {
        [colors addObject:[NSColor whiteColor]];
    }
    
    NSMutableArray *refs = @[].mutableCopy;
    
    
    if(self.showTraining.state == NSOnState){
        UInt8 * tempMask = [self createImageForTraining];
        [self addUint8Buffer:tempMask toStack:refs direction:YES];
    }
    
    if(self.showPMap.state == NSOnState){
        UInt8 * tempMask = [self createImageForClassification];
        [self addUint8Buffer:tempMask toStack:refs direction:YES];
    }
    
    if(self.showImage.state == NSOnState){
        //TODO enable pixel data here
        CGImageRef ref = NULL;
        if(self.showPixelData.state == NSOffState){
            NSInteger channel = self.channelTableView.selectedRow;
            if(channel != NSNotFound){
                NSInteger size = [self maskPlaneLength];
                UInt8 * image = calloc(size, sizeof(UInt8));
                NSInteger virtualSlice = (NSInteger)([self mask].slices * self.planeSelector.floatValue);
                
                int * subMaskPlane = &[self mask].maskIds[virtualSlice * size];
                float ** maskData = [self mask].computedData;
                NSInteger channel = self.channelTableView.selectedRow;
                
                float max = .0f;
                NSInteger segments = [self mask].segmentedUnits;
                for (NSInteger i = 0; i < segments; i++)
                    if(maskData[channel][i] > max)
                        max = maskData[channel][i];
                
                for (NSInteger i = 0; i < size; i++) {
                    if(subMaskPlane[i] > 0){
                        image[i] = (UInt8)(maskData[channel][subMaskPlane[i]]/max * 255);
                    }
                }
                ref = [IMCImageGenerator imageFromCArrayOfValues:image color:[NSColor whiteColor] width:[self mask].width height:[self mask].height startingHueScale:0 hueAmplitude:170 direction:NO ecuatorial:NO brightField:NO];
                
                free(image);
            }
        }
        if(self.showPixelData.state == NSOnState){
//            IMCImageStack *stack = self.trainer.computation.mask.imageStack;
//            NSMutableArray *foundChannels = @[].mutableCopy;
//            NSMutableArray *colors = @[].mutableCopy;
//            [self.channelTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
//                NSInteger foundPixChannel = [stack ascertainIndexInStackForComputationChannel:self.trainer.computation.originalChannels[idx]];
//                if(foundPixChannel == NSNotFound)
//                    foundPixChannel = [stack ascertainIndexInStackForComputationChannel:self.trainer.computation.channels[idx]];
//                if(foundPixChannel != NSNotFound){
//                    [foundChannels addObject:@(foundPixChannel)];
//                    [colors addObject:[NSColor whiteColor]];
//                }
//                
//            }];
//            
//            if(!stack.isLoaded)
//                [stack loadLayerDataWithBlock:nil];
//            while(!stack.isLoaded);
//            
//            ref = [[IMCImageGenerator imageForImageStacks:@[stack].mutableCopy
//                                                  indexes:foundChannels
//                                         withColoringType:0
//                                             customColors:self.pixelsColoring.selectedSegment == 0?colors:nil
//                                        minNumberOfColors:3
//                                                    width:stack.width
//                                                   height:stack.height
//                                           withTransforms:NO
//                                                    blend:kCGBlendModeScreen
//                                                 andMasks:self.showMaskBorder.state == NSOnState?@[self.trainer.computation.mask]:nil
//                                          andComputations:nil
//                                               maskOption:MASK_ONE_COLOR_BORDER
//                                                 maskType:MASK_ALL_CELL
//                                          maskSingleColor:[NSColor whiteColor]
//                                          isAlignmentPair:NO
//                                              brightField:NO]CGImage];
        }
        
        //        NSImage *image = [IMCImageGenerator imageForImageStacks:nil indexes:self.inOrderIndexes withColoringType:0 customColors:nil minNumberOfColors:3 width:self.trainer.computation.mask.imageStack.width height:self.trainer.computation.mask.imageStack.height withTransforms:NO blend:kCGBlendModeScreen andMasks:nil andComputations:@[self.trainer.computation] maskOption:0 maskType:MASK_ALL_CELL maskSingleColor:nil isAlignmentPair:NO brightField:NO];
        if(ref)
            [refs addObject:(__bridge id)ref];
    }
    NSImage *final = [IMCImageGenerator imageWithArrayOfCGImages:refs width:[self mask].width height:[self mask].height blendMode:kCGBlendModeOverlay];
    
    self.scrollView.imageView.image = final;
}

@end
