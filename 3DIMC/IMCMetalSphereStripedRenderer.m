//
//  IMCMetalSphereStripedRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 11/20/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalSphereStripedRenderer.h"

@implementation IMCMetalSphereStripedRenderer

-(void)updateColorBuffer{
    
    self.cellsToRender = 0;
    float ** data = [self.computation computedData];
    if(data){
        AlphaMode alphaMode = [self.delegate alphaMode];
        int stride = 8;
        
        NSInteger segments = self.computation.segmentedUnits;
        float * buff = calloc(segments * stride, sizeof(float));
        if(buff){
            self.colorsObtained = [self.delegate colors];
            float minThresholdForAlpha = [self.delegate combinedAlpha];
            
            float * colors = (float *)malloc(self.colorsObtained.count * 3 * sizeof(float));
            
            for (int i = 0; i< self.colorsObtained.count; i++) {
                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
                colors[i * 3] = colorObj.redComponent/255.0f;
                colors[i * 3 + 1] = colorObj.greenComponent/255.0f;
                colors[i * 3 + 2] = colorObj.blueComponent/255.0f;
            }
            
            NSInteger channels = self.indexesObtained.count;
            
            float * xCentroids = [self.computation xCentroids];
            float * yCentroids = [self.computation yCentroids];
            float * zCentroids = [self.computation zCentroids];
            float * sizes = [self.computation sizes];
            float defaultThicknessValue = [self.delegate defaultThicknessValue];
            float maxes[channels];
            for (NSInteger idx = 0; idx < channels; idx++)
                maxes[idx] = [self.computation maxChannel:[self.indexesObtained[idx]integerValue]];
            
            //int allInts [10] = {405, 162, 162, 162, 162, 162, 162, 162, 162, 243};
            
            for (NSInteger i = 0; i < segments; i++) {
                NSInteger internalCursor = i * stride;
                for (NSInteger idx = 0; idx < channels; idx++) {
                    NSInteger realIndex = [self.indexesObtained[idx]integerValue];
                    
                    UInt8 val = (UInt8)((data[realIndex][i]/maxes[idx]) * 255.0f);
                    if(self.colorsObtained.count > 0){
                        buff[internalCursor + 1] += val * colors[idx * 3];
                        buff[internalCursor + 2] += val * colors[idx * 3 + 1];
                        buff[internalCursor + 3] += val * colors[idx * 3 + 2];
                    }else{
                        RgbColor rgb = RgbFromFloatUnit(val/255.0f);
                        buff[internalCursor + 1] += rgb.r/255.0f;
                        buff[internalCursor + 2] += rgb.g/255.0f;
                        buff[internalCursor + 3] += rgb.b/255.0f;
                    }
                    buff[internalCursor + 4] = xCentroids[i];
                    buff[internalCursor + 5] = yCentroids[i];
                    buff[internalCursor + 6] = zCentroids[i] * defaultThicknessValue;
                    buff[internalCursor + 7] = powf((3 * sizes[i]) / (4 * M_PI) , 1.0f/3);//Size
                    
                    //Filters
                    float max = .0f;
                    float sum = .0f;
                    for (int j = 1; j < 4; j++){
                        float val = buff[internalCursor + j];
                        if(val > max)
                            max = val;
                        sum += val;
                        if(sum > 1.0f){
                            sum = 1.0f;
                            break;
                        }
                    }
                    
                    if(alphaMode == ALPHA_MODE_OPAQUE)
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : 1.0f;
                    if(alphaMode == ALPHA_MODE_FIXED)
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : minThresholdForAlpha;//Alpha
                    if(alphaMode == ALPHA_MODE_ADAPTIVE)
                        buff[internalCursor] = max < minThresholdForAlpha ? 0.0f : sum;//MIN(1.0f, sum);//Alpha
                }
            }
            NSInteger bufferSize = segments * stride;
            float * cleanBuffer = malloc(bufferSize * sizeof(float));
            
            //Remove all Zeroes
            NSInteger cleanIndex = 0;
            for (NSInteger m = 0; m < bufferSize; m+=stride)
                if(buff[m] > 0){
                    for (NSInteger n = 0; n < stride; n++)
                        cleanBuffer[cleanIndex + n] = buff[m + n];
                    cleanIndex += stride;
                }
            
            self.cellsToRender = cleanIndex/stride;
            cleanBuffer = realloc(cleanBuffer, sizeof(float) * cleanIndex);
            self.colorBuffer = [self.device newBufferWithBytes:cleanBuffer length:cleanIndex * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            
            NSLog(@"-%li", self.cellsToRender);
            
            free(buff);
            //free(cleanBuffer);
            free(colors);
        }
    }
}

@end
