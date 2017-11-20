//
//  IMC3DVideoPrograms.m
//  3DIMC
//
//  Created by Raul Catena on 11/16/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMC3DVideoPrograms.h"
#import "IMCVideoCreator.h"
#import "IMCMtkView.h"

@implementation IMC3DVideoPrograms

+(void)addBuffer:(UInt8 *)frameBuffer toVideoRecorder:(IMCVideoCreator *)videoRecorder{
    [videoRecorder addBuffer:frameBuffer];
    free(frameBuffer);
}

+(void)recordYVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView active:(BOOL *)activeFlag{
    
    NSString *degrees;
    do {
        degrees = [IMCUtils input:@"Degrees per frame" defaultValue:@"1.0"];
        if(!degrees)
            return;
    } while (fabs(degrees.floatValue) <= .0f || fabs(degrees.floatValue) >= 90.0f);
    

    dispatch_queue_t aQ = dispatch_queue_create("aQQQ", NULL);
    dispatch_async(aQ, ^{
        
        NSInteger steps = roundf(360.0f / degrees.floatValue);
        IMCVideoCreator *videoRecorder = [[IMCVideoCreator alloc]initWithSize:sizeFrame duration:frameDuration path:fullPath];
        
        for (int i = 0; i < steps; i++) {
            
            if(*activeFlag == FALSE)
                break;
            
            [metalView rotateX:0 Y:2*M_PI/steps Z:0];
            metalView.refresh = YES;
            while (metalView.refresh);
            id<MTLTexture> old = metalView.lastRenderedTexture;
            while (old == metalView.lastRenderedTexture);
            [IMC3DVideoPrograms addBuffer:(UInt8 *)[metalView captureData] toVideoRecorder:videoRecorder];
        }
        [videoRecorder finishVideo];
    });
}
+(void)recordStackVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView slices:(NSInteger)slices active:(BOOL *)activeFlag{
    
    NSInteger invert = [IMCUtils inputOptions:@[@"Top to down", @"Bottom to top"] prompt:@"Select direction"];
    if(invert != NSNotFound){
        IMCVideoCreator *videoRecorder = [[IMCVideoCreator alloc]initWithSize:sizeFrame duration:frameDuration path:fullPath];
        
        dispatch_queue_t aQ = dispatch_queue_create("aQQQ", NULL);
        dispatch_async(aQ, ^{
            BOOL backwards = (BOOL)invert;
            float factor = !backwards ? 1.0f/slices : -1.0f/slices;
            float beggining = !backwards ? 1.0f : .0f;
            float end = !backwards ? .0f : 1.0f;
            
            for (float thick = beggining; thick >= end; thick -= factor) {
                
                if(*activeFlag == FALSE)
                    break;
                
                if(!backwards)metalView.nearZOffset = thick;
                else metalView.farZOffset = thick;
                
                id<MTLTexture> old = metalView.lastRenderedTexture;
                metalView.refresh = YES;
                while (old == metalView.lastRenderedTexture);
                [IMC3DVideoPrograms addBuffer:(UInt8 *)[metalView captureData] toVideoRecorder:videoRecorder];
            }
            [videoRecorder finishVideo];
        });
    }
}

+(void)recordSliceVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView slices:(NSInteger)slices active:(BOOL *)activeFlag{
    
    NSString *perc;
    do {
        perc = [IMCUtils input:@"Percentage thickness to see in each frame..." defaultValue:@"10"];
        if(!perc)
            return;
    } while (fabs(perc.floatValue) <= .0f || fabs(perc.floatValue) >= 90.0f);
    
    IMCVideoCreator *videoRecorder = [[IMCVideoCreator alloc]initWithSize:sizeFrame duration:16 path:fullPath];
    dispatch_queue_t aQ = dispatch_queue_create("aQQQ", NULL);
    dispatch_async(aQ, ^{
        BOOL backwards = perc.floatValue < 0;
        float factor = !backwards ? 1.0f/slices : -1.0f/slices;
        float see = fabs(perc.floatValue / 100);
        float beggining = !backwards ? 1.0f - see : .0f;
        float end = !backwards ? .0f : 1.0f - see;
        
        for (float thick = beggining; !backwards ? thick >= end : thick < end; thick -= factor) {
            
            if(*activeFlag == FALSE)
                break;
            
            metalView.nearZOffset = thick;
            metalView.farZOffset = thick + see;
            id<MTLTexture> old = metalView.lastRenderedTexture;
            metalView.refresh = YES;
            while (old == metalView.lastRenderedTexture);
            [IMC3DVideoPrograms addBuffer:(UInt8 *)[metalView captureData] toVideoRecorder:videoRecorder];
        }
        [videoRecorder finishVideo];
    });
}

+(void)recordRockVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView active:(BOOL *)activeFlag{
    
    NSString *perc;
    do {
        perc = [IMCUtils input:@"Rock angle amplitude..." defaultValue:@"80"];
        if(!perc)
            return;
    } while (perc.floatValue <= .0f || perc.floatValue >= 180.0f);
    
    IMCVideoCreator *videoRecorder = [[IMCVideoCreator alloc]initWithSize:sizeFrame duration:16 path:fullPath];
    dispatch_queue_t aQ = dispatch_queue_create("aQQQ", NULL);
    dispatch_async(aQ, ^{
        float stepSize = 2 * M_PI/1000;
        NSInteger stepsToTake = perc.integerValue;
        for (int i = 0; i< stepsToTake; i++) {
            
            if(*activeFlag == FALSE)
                break;
            
            if(i < stepsToTake/4)
                [metalView rotateX:0 Y:stepSize Z:-stepSize];
            else if(i < stepsToTake/2)
                [metalView rotateX:stepSize Y:0 Z:stepSize];
            else if(i < stepsToTake/4 * 3)
                [metalView rotateX:0 Y:-stepSize Z:stepSize];
            else
                [metalView rotateX:-stepSize Y:0 Z:-stepSize];
            metalView.refresh = YES;
            while (metalView.refresh);
            id<MTLTexture> old = metalView.lastRenderedTexture;
            while (old == metalView.lastRenderedTexture);
            [IMC3DVideoPrograms addBuffer:(UInt8 *)[metalView captureData] toVideoRecorder:videoRecorder];
        }
        [videoRecorder finishVideo];
    });
}

@end
