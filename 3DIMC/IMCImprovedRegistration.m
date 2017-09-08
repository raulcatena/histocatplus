//
//  IMCImprovedRegistration.m
//  IMCReader
//
//  Created by Raul Catena on 12/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCImprovedRegistration.h"

@implementation IMCImprovedRegistration

+(void)clearBufferSource:(UInt8 *)source withWidth:(int)width{
    for (NSInteger i = 0; i < width * width; i++) {
        source[i] = 0;
    }
}

+(void)rotateCanvas:(CGContextRef)canvas withTransform:(CGAffineTransform)transform angle:(float)angle widthMidXtrans:(float)midXTrans andMidthMidYtrans:(float)midYTrans{
    transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, midXTrans, midYTrans);
    transform = CGAffineTransformRotate(transform, angle);
    transform = CGAffineTransformTranslate(transform, -midXTrans, -midYTrans);
    CGContextConcatCTM(canvas, transform);
}

+(void)translateCanvas:(CGContextRef)canvas withTransform:(CGAffineTransform)transform xTrans:(float)xTrans andYtrans:(float)yTrans{
    transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, xTrans, yTrans);
    CGContextConcatCTM(canvas, transform);
}

+(float)radiansToDegrees:(float)radians{
    return radians * 180 / M_PI;
}

-(NSArray *)startRegistration:(NSInteger **)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep xRange:(NSInteger)xTranslationRange yRange:(NSInteger)yTranslationRange{
    if(sourceImg == NULL || targetImg == NULL)return NULL;
    
    int stepsAngle = (int)ceil((angleRange * 2)/angleStep);
    NSLog(@"Steps Angle %i", stepsAngle);
    NSLog(@"Angle Range Angle Step %f %f", angleRange, angleStep);
    
    float max = MAX(MAX(CGImageGetWidth(sourceImg), CGImageGetHeight(sourceImg)),
                    MAX(CGImageGetWidth(targetImg), CGImageGetHeight(targetImg)));
    
    NSInteger total = (NSInteger)max * max;
    
    void * oriBuffer = calloc(total, sizeof(UInt8));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
    CGContextRef canvas = CGBitmapContextCreate(oriBuffer, max, max, 8, max, colorSpace, kCGImageAlphaNone);
    CGRect frame = CGRectMake(0, 0, max, max);
    CGContextDrawImage(canvas, frame, sourceImg);
    
    void * destBuffer = calloc(total, sizeof(UInt8));
    CGContextRef rotCanvas = CGBitmapContextCreate(destBuffer, max, max, 8, max, colorSpace, kCGImageAlphaNone);
    
    
    UInt8 * bufferSource = (UInt8 *)oriBuffer;
    UInt8 * bufferDest = (UInt8 *)destBuffer;
    
    //Initial rotation
    CGAffineTransform transform = CGAffineTransformIdentity;
    [IMCImprovedRegistration rotateCanvas:rotCanvas withTransform:transform angle:-angleRange widthMidXtrans:max/2 andMidthMidYtrans:max/2];
    CGContextDrawImage(rotCanvas, frame, targetImg);
    
    NSInteger numberCases = xTranslationRange * yTranslationRange * stepsAngle;
    printf("%li examining", numberCases);
    NSInteger *vals = calloc(numberCases, sizeof(NSInteger));
    
    NSInteger *hits = calloc(numberCases, sizeof(NSInteger));
    
    
    int counter = 0;
    
    for (int l = 0; l < stepsAngle; l++) {
        //Go to origin
        [IMCImprovedRegistration translateCanvas:rotCanvas withTransform:transform xTrans:-xTranslationRange/2 andYtrans:-yTranslationRange/2];
        
        for (int i = 0; i < yTranslationRange; i++) {
            for (int j = 0; j < xTranslationRange; j++) {
                //Measure
                [IMCImprovedRegistration clearBufferSource:bufferDest withWidth:max];
                CGContextDrawImage(rotCanvas, frame, targetImg);
                
                NSInteger sum = 0;
                NSInteger hitCount = 0;
                for (NSInteger c = 0; c < total; c++ ) {
                    if(bufferSource[c] == 80 && bufferDest[c] == 80){
                        sum += bufferSource[c];
                        sum += bufferDest[c];
                        hitCount++;
                    }
                }
                vals[counter] = sum;
                hits[counter] = hitCount;
                counter++;
                
                //Translate X
                [IMCImprovedRegistration translateCanvas:rotCanvas withTransform:transform xTrans:1.0f andYtrans:.0f];
            }
            //Translate Y, take X back
            [IMCImprovedRegistration translateCanvas:rotCanvas withTransform:transform xTrans:-xTranslationRange andYtrans:1.0f];
        }
        //Translate X and Y to origin
        [IMCImprovedRegistration translateCanvas:rotCanvas withTransform:transform xTrans:xTranslationRange/2 andYtrans:-yTranslationRange/2];
        NSLog(@"done angle\n");
        
        //Rotate next angle case
        [IMCImprovedRegistration rotateCanvas:rotCanvas withTransform:transform angle:angleStep widthMidXtrans:max/2 andMidthMidYtrans:max/2];
    }
    
    //Restore angle and prepare return
    [IMCImprovedRegistration clearBufferSource:bufferDest withWidth:max];
    [IMCImprovedRegistration rotateCanvas:rotCanvas withTransform:transform angle:-angleRange widthMidXtrans:max/2 andMidthMidYtrans:max/2];
    CGContextDrawImage(rotCanvas, frame, targetImg);
    
    NSInteger foundMax = 0;
    int maxInd = 0;
    int repeats = 0;
    
    NSInteger hitsMax = 0;
    int hitInd = 0;
    int repeatsHits = 0;
    
    
    for (int i = 0; i < numberCases; i ++) {
        if(vals[i] == foundMax && foundMax !=0)repeats++;
        if(vals[i] > foundMax){
            repeats = 0;
            foundMax = vals[i];
            maxInd = i;
        }
        if(hits[i] == hitsMax && hitsMax !=0){
            repeatsHits++;
        }
        if(hits[i] > hitsMax){
            hitsMax = hits[i];
            hitInd = i;
        }
    }
    printf("repeats %i %i", repeats, repeatsHits);
    printf("----Best cond: %i %i with Max %li\n", maxInd, hitInd, foundMax);
    NSInteger sizeAnglesBlock = xTranslationRange * yTranslationRange;
    printf("size angles block %li\n", (long)sizeAnglesBlock);
    int angleIndex = (int)maxInd/sizeAnglesBlock - stepsAngle/2;
    int xy = maxInd%sizeAnglesBlock;
    NSInteger y = xy/(int)yTranslationRange - yTranslationRange/2;
    NSInteger x = xy%(int)xTranslationRange - xTranslationRange/2;
    printf("optimal x %li\n", (long)x);
    printf("optimal y %li\n", (long)y);
    printf("optimal a %i\n", angleIndex);
    
    printf("degrees %f", [IMCImprovedRegistration radiansToDegrees:angleIndex * angleStep]);
    
    CFRelease(canvas);
    CFRelease(rotCanvas);
    free(oriBuffer);
    free(destBuffer);
    CFRelease(sourceImg);
    CFRelease(targetImg);
    
    NSLog(@"Address vals %p", vals);
    *capture = vals;
    NSLog(@"Address capture %p", capture);
    
    return @[[NSValue valueWithPoint:NSMakePoint(x, y)], [NSNumber numberWithFloat:[IMCImprovedRegistration radiansToDegrees:angleIndex * angleStep]]];
}

@end
