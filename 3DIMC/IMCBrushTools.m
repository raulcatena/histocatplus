//
//  IMCBrushTools.m
//  3DIMC
//
//  Created by Raul Catena on 2/14/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCBrushTools.h"
#import "IMCMasks.h"

@interface IMCBrushTools(){
    float * brushValues;
}

@end

@implementation IMCBrushTools

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)changedValue:(id)sender{
    if(sender ==  self.tolerance)
        self.toleranceText.stringValue = [NSString stringWithFormat:@"%.2f", self.tolerance.floatValue];
    if(sender ==  self.brushSize)
        self.brushSizeText.stringValue = [NSString stringWithFormat:@"%li px", self.brushSize.integerValue];
    
    if(brushValues)free(brushValues);
    brushValues = NULL;
}

-(BrushType)brushType{
    return (BrushType)self.typeOfBrush.selectedSegment;
}

-(void)getBrushDistanceValuesWithDiameter:(int)diameter{
    if(brushValues != NULL)free(brushValues);
    brushValues = calloc(pow(diameter , 2), sizeof(float));
    int clock = 0;
    int radius = (diameter - 1)/2;
    for (int i = -radius; i< radius + 1; i++) {
        for (int j = -radius; j< radius + 1; j++) {
            brushValues[clock] = roundf(sqrt(pow(j, 2) + pow(i, 2)));
            clock++;
        }
    }
}

-(void)paintOrRemove:(BOOL)remove mask:(UInt8 *)paintMask index:(NSInteger)index fillInteger:(NSInteger)fill imageWidth:(NSInteger)width imageHeight:(NSInteger)heigth{
    
    NSInteger total = width * heigth;
    int radius = (self.brushSize.intValue - 1)/2;
    
    paintMask[index] = remove == YES?0:fill;
    
    if(brushValues == NULL)
        [self getBrushDistanceValuesWithDiameter:self.brushSize.intValue];
    
    int clock = 0;
    
    for (int i = -radius; i < radius + 1; i++) {
        for (int j = -radius; j < radius + 1; j++) {
            NSInteger otherIndex = index + j * width + i;
            if(brushValues[clock] <= radius)
                if(doesNotJumpLine(index, otherIndex, width, heigth, total, radius) == YES)
                    paintMask[otherIndex] = remove == YES?0:fill;
            clock++;
        }
    }
}
-(void)paintOrRemove:(BOOL)remove mask32Bit:(int *)paintMask index:(NSInteger)index fillInteger:(int)fill imageWidth:(NSInteger)width imageHeight:(NSInteger)heigth{
    
    NSInteger total = width * heigth;
    
    int radius = (self.brushSize.intValue - 1)/2;
    
    paintMask[index] = remove == YES?0:fill;
    
    if(brushValues == NULL)
        [self getBrushDistanceValuesWithDiameter:self.brushSize.intValue];
    
    int clock = 0;
    
    for (int i = -radius; i < radius + 1; i++) {
        for (int j = -radius; j < radius + 1; j++) {
            NSInteger otherIndex = index + j * width + i;
            if(brushValues[clock] <= radius)
                if(doesNotJumpLine(index, otherIndex, width, heigth, total, radius) == YES)
                    paintMask[otherIndex] = remove == YES?0:fill;
            clock++;
        }
    }
}

//RCF Refactor more

-(void)fillBufferMask:(UInt8 *)paintMask fromDataBuffer:(UInt8 *)buffer index:(NSInteger)index width:(NSInteger)width height:(NSInteger)height fill:(NSInteger)fill{
    
    NSInteger total = width * height;
    
    if(paintMask == NULL)return;
    
    uint8_t value = *(uint8_t *)&buffer[index * 4];
    
    paintMask[index] = 1;
    
    int toleranceVal = self.tolerance.floatValue * 120;//Aprox half of 255
    
    for (int dis = 1; dis < MAX(width, height); dis++) {
        
        BOOL found = NO;
        for (int x = -dis; x < dis + 1; x++) {
            for (int y = -dis; y < dis + 1; y++) {
                
                if(abs(x) < dis && abs(y) < dis)continue;
                NSInteger testIndex = index + x + y*width;
                
                if(doesNotJumpLine(index, testIndex, width, height, total, dis) == YES){
                    uint8_t testVal = *(uint8_t *)&buffer[testIndex * 4];
                    if(testVal > value - toleranceVal && testVal < value + toleranceVal){
                        for (int m = -1; m < 2; m++) {
                            for (int n = -1; n < 2; n++) {
                                NSInteger recheckIndex = testIndex + m + n * width;
                                if(doesNotJumpLine(testIndex, recheckIndex, width, height, total, 2) == YES){
                                    if (paintMask[recheckIndex] > 0) {
                                        found = YES;
                                        paintMask[testIndex] = fill;//1 RCF
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if(found == NO)break;
    }
}

-(void)dealloc{
    if(brushValues)free(brushValues);
}

@end
