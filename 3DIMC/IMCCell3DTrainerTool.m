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

@interface IMCCell3DTrainerTool(){
    BOOL updating;
}

@end

@implementation IMCCell3DTrainerTool

-(IMC3DMask *)mask{
    return (IMC3DMask *)self.trainer.computation;
}
-(NSInteger)maskPlaneLength{
    return [self mask].width * [self mask].height;
}

#pragma mark mask painting
-(void)clickedAtPoint:(NSPoint)point{
    if(self.labelsTableView.selectedRow !=  NSNotFound){
        NSLog(@"%li LTV index", self.labelsTableView.selectedRow);
        NSPoint processed = [self.scrollView getTranslatedPoint:point];
        
        NSInteger plane = [self mask].width * [self mask].height;
        NSInteger virtualSlice = [self virtualSlice];
        
        NSLog(@"%li virtual slice", virtualSlice);
        
        NSInteger pix = MAX(0, MIN(plane - 1, floor(processed.y) * [self mask].width + processed.x));
        
        NSLog(@"%li PIX", pix);
        
        int cellId = abs([self mask].maskIds[virtualSlice * plane + pix]);
        
        NSLog(@"%i Cell Id", cellId);
        
        if(self.trainingBuff)
            NSLog(@"%p is the training buffer", self.trainingBuff);
        else
            NSLog(@"%p is the training buffer NULL pointer", self.trainingBuff);
        
        if(cellId > 0)
            [self trainingBuff][cellId - 1] = [self trainingBuff][cellId - 1] == 0 ? (int)self.labelsTableView.selectedRow + 1 : 0;
        
        [self.trainer.trainingNodes.firstObject regenerateDictTraining];
        [self refresh];
    }
}

-(NSInteger)virtualSlice{
    return MAX(0, MIN((NSInteger)([self mask].slices * self.planeSelector.floatValue), [self mask].slices - 1));
}

-(UInt8 *)createImageForClassification{
    
    if(!self.trainer.randomFResults)
        return NULL;
    
    NSInteger size = [self maskPlaneLength];
    NSInteger fullMask = size * [self mask].slices;
    int * copy = (int *)calloc(size, sizeof(int));
    NSInteger virtualSlice = [self virtualSlice];
    
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
    NSInteger virtualSlice = [self virtualSlice];
    
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
    
    //const CGFloat myMaskingColors[6] = { 0, 100, 0, 100, 0, 100 };
    //CGImageRef masked = CGImageCreateWithMaskingColors (refi, myMaskingColors);
    
    //if(masked)
    //    [stackRefs addObject:(__bridge id)masked];
    
    if(refi)
        [stackRefs addObject:(__bridge id)refi];
//    if(refi)
//        CFRelease(refi);
    
    if(buffer)
        free(buffer);
}
-(void)refresh{
    updating = YES;
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
        
        if(self.showPixelData.state == NSOffState){
            __block int counter = 0;
            NSArray <NSColor *>*colors = @[
                                [NSColor blueColor],
                                [NSColor greenColor],
                                [NSColor redColor],
                                [NSColor cyanColor],
                                [NSColor yellowColor],
                                [NSColor magentaColor]
                                ];
            [self.channelTableView.selectedRowIndexes.copy enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                CGImageRef ref = NULL;
                NSInteger size = [self maskPlaneLength];
                UInt8 * image = calloc(size, sizeof(UInt8));
                NSInteger virtualSlice = [self virtualSlice];
                int * subMaskPlane = &[self mask].maskIds[virtualSlice * size];
                float ** maskData = [self mask].computedData;
                
                float max = .0f;
                NSInteger segments = [self mask].segmentedUnits;
                for (NSInteger i = 0; i < segments; i++)
                    if(maskData[idx][i] > max)
                        max = maskData[idx][i];
                
                max *= self.saturate.floatValue;
                
                for (NSInteger i = 0; i < size; i++) {
                    if(subMaskPlane[i] > 0){
                        image[i] = (UInt8)(maskData[idx][subMaskPlane[i]-1]/max * 255);
                    }
                }
                
                NSColor *color = colors[counter];
                ref = [IMCImageGenerator imageFromCArrayOfValues:image color:color width:[self mask].width height:[self mask].height startingHueScale:0 hueAmplitude:170 direction:NO ecuatorial:NO brightField:NO];
                if(ref)
                    [refs addObject:(__bridge id)ref];
                free(image);
                counter++;
                if(counter == 5)
                    *stop = YES;
            }];
        }
    }
    NSImage *final = [IMCImageGenerator imageWithArrayOfCGImages:refs width:[self mask].width height:[self mask].height blendMode:kCGBlendModeScreen];
    
    self.scrollView.imageView.image = final;
    updating = NO;
}

#pragma mark imcscrollviewdelegate

-(void)altScrolledWithEvent:(NSEvent *)event{
    self.planeSelector.floatValue = MAX(.0f, MIN(1.0f, self.planeSelector.floatValue + event.deltaY * 0.005f));
    if(!updating)
        [self refresh];
}

@end
