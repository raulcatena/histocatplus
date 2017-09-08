//
//  IMCRegistration.m
//  3DIMC
//
//  Created by Raul Catena on 2/1/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCRegistration.h"

@implementation IMCRegistration

+(void)clearBufferSource:(UInt8 *)source withWidth:(int)width{
    for (NSInteger i = 0; i < width * width; i++) {
        source[i] = 0;
    }
}

+(void)transformCanvas:(CGContextRef)canvas angle:(float)angle xTrans:(float)xTrans andYtrans:(float)yTrans  widthMidXtrans:(float)midXTrans andMidthMidYtrans:(float)midYTrans{
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, midXTrans, midYTrans);
    transform = CGAffineTransformRotate(transform, angle);
    transform = CGAffineTransformTranslate(transform, -midXTrans + xTrans, -midYTrans + yTrans);
    CGContextConcatCTM(canvas, transform);
}

+(float)radiansToDegrees:(float)radians{
    return radians * 180 / M_PI;
}
+(NSInteger)sumOfArray:(uint8 *)array length:(NSInteger)length{
    float sum = .0f;
    for (NSInteger i = 0; i < length; i++) {
        sum += array[i];
    }
    return sum;
}
+(float)sumOfFloatArray:(float *)array length:(NSInteger)length{
    float sum = .0f;
    for (NSInteger i = 0; i < length; i++) {
        sum += array[i];
    }
    return sum;
}
+(float)averageOfArray:(UInt8 *)array length:(NSInteger)length{
    float sum = [self sumOfArray:array length:length];
    return sum/length;
}
+(float *)diffsArrayForArray:(UInt8 *)array length:(NSInteger)length{
    float * result = (float *)malloc(length * sizeof(float));
    float avg = [self averageOfArray:array length:length];
    for (NSInteger i = 0; i < length; i++) {
        result[i] = (float)array[i] - avg;
    }
    return result;
}
+(float)correlationForArrayDiffs:(float *)diffsArray withArray:(UInt8 *)array length:(NSInteger)length{
    //float av1 = [self averageOfArray:array1 length:length];
    float av = [self averageOfArray:array length:length];
    
    float sumAB = .0f;
    float sumBB = .0f;
    float sumAA = .0f;
    
    for (NSInteger i = 0; i < length; i++) {
        float b = array[i] - av;
        float a = diffsArray[i];
        sumAB += a * b;
        sumBB += b * b;
        sumAA += a * a;
    }
    
    return sumAB/sqrt(sumAA * sumAB);
}
+(NSInteger)matchesForArrays:(UInt8 *)source withArray:(UInt8 *)target length:(NSInteger)length{
    NSInteger hits = 0;
    for (NSInteger i = 0; i < length; i++)
        if(source[i] > 0)
            if(source[i] == target[i])
                hits++;
    return hits;
}
+(NSUInteger)simpleMutualInformation:(UInt8 *)source withArray:(UInt8 *)target length:(NSInteger)length{
    
    NSUInteger sum = 0;
    for (NSInteger i = 0; i < length; i++) {
        if(source[i] > 80 && target[i] > 80)
            sum += (source[i] + target[i]);
    }
    
    return sum;
}



+(CGImageRef)startRegistrationOld:(NSInteger *)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep xRange:(NSInteger)xTranslationRange yRange:(NSInteger)yTranslationRange destDict:(NSMutableDictionary *)dest{
    if(sourceImg == NULL || targetImg == NULL)return NULL;
    
    int stepsAngle = (int)ceil((angleRange * 2)/angleStep);
    //NSLog(@"Steps Angle %i", stepsAngle);
    //NSLog(@"Angle Range Angle Step %f %f", angleRange, angleStep);
    
    float max = MAX(MAX(CGImageGetWidth(sourceImg), CGImageGetHeight(sourceImg)),
                    MAX(CGImageGetWidth(targetImg), CGImageGetHeight(targetImg)));
    
    //NSLog(@"Max %f", max);
    //NSLog(@"vals %zu %zu %zu %zu", CGImageGetWidth(sourceImg), CGImageGetHeight(sourceImg),CGImageGetWidth(targetImg), CGImageGetHeight(targetImg))
    ;
    float subset = max * .5f;
    //return rand()%2 == 0? targetImg:sourceImg;
    NSInteger total = (NSInteger)subset * subset;
    
    void * oriBuffer = calloc(total, sizeof(UInt8));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
    CGContextRef canvas = CGBitmapContextCreate(oriBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    CGRect frame = CGRectMake(-subset/2, -subset/2, max, max);
    CGContextDrawImage(canvas, frame, sourceImg);
    
    
    void * destBuffer = calloc(total, sizeof(UInt8));
    CGContextRef rotCanvas = CGBitmapContextCreate(destBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    
    UInt8 * bufferSource = (UInt8 *)oriBuffer;
    UInt8 * bufferDest = (UInt8 *)destBuffer;
    
    NSInteger numberCases = xTranslationRange * yTranslationRange * stepsAngle;
    printf("\n%li examining\n", numberCases);
    NSInteger *vals = (NSInteger *)calloc(numberCases, sizeof(NSInteger));
    NSInteger *hits = (NSInteger *)calloc(numberCases, sizeof(NSInteger));
    
    
    BOOL improving = YES;
    
    NSInteger brushThickness = 2;
    NSInteger brushDiameter = brushThickness * 2 + 1;
    NSInteger toleranceToDecrease = 200;
    NSInteger tolerating = 0;
    NSInteger lastBestIndex = 0;
    
    NSInteger cumA = 0;
    NSInteger cumX = 0;
    NSInteger cumY = 0;
    
    NSInteger localCombinations = (int)pow(brushDiameter, 3.0f);
    //NSLog(@"Local combinations %li", localCombinations);
    NSInteger totalCounter = 0;
    
    NSMutableArray *visitedMaxes = @[].mutableCopy;
    NSArray *maxima;
    
    
    
    float * diffsCanvas = [self diffsArrayForArray:bufferSource length:total];
    
    while (improving){
        
        NSInteger localCounter = 0;
        NSInteger localResults[localCombinations];
        
        for (NSInteger a = -brushThickness; a < brushThickness + 1; a++) {
            
            for (NSInteger y = -brushThickness; y < brushThickness + 1; y++) {
                
                for (NSInteger x = -brushThickness; x < brushThickness + 1; x++) {
                    
                    //for (NSInteger cx = -brushThickness; cx < brushThickness + 1; cx++) {
                        
                        //for (NSInteger cy = -brushThickness; cy < brushThickness + 1; cy++) {
                    
                            NSInteger indexResults = (numberCases/2)
                            + (cumA + a) * xTranslationRange * yTranslationRange
                            + (xTranslationRange * yTranslationRange)/2 + (cumY + y) * xTranslationRange
                            + xTranslationRange/2 + (cumX + x);
                            
                            //NSLog(@"Layer %li x %li y %li Idx: %li", cumA + a, cumX + x, cumY + y, indexResults);
                            
                            localResults[localCounter] = indexResults;
                            localCounter++;
                            
                            if(indexResults < 0)continue;
                            if(vals[indexResults] != 0)continue;
                            
                            //Paint
                            frame = CGRectMake(-subset/2, -subset/2, max, max);
                            [IMCRegistration clearBufferSource:bufferDest withWidth:subset];
                            
                            CGContextSaveGState(rotCanvas);
                            [self transformCanvas:rotCanvas angle:(cumA + a) * angleStep xTrans:cumX + x andYtrans:cumY + y widthMidXtrans:subset/2 andMidthMidYtrans:subset/2];
                            CGContextDrawImage(rotCanvas, frame, targetImg);
                            CGContextRestoreGState(rotCanvas);
                            
                            totalCounter++;
                            
                            
                            vals[indexResults] = (NSInteger)([IMCRegistration correlationForArrayDiffs:diffsCanvas withArray:bufferDest length:total] * 1000000);
                            hits[indexResults] = 100;
                        //}
                    //}
                }
            }
        }
        
        
        //Check best
        NSInteger localMax = 0;
        NSInteger localMaxIndex = 0;
        
        for (NSInteger i = 0; i < localCombinations; i++){
            if(localResults[i] < 0)
                continue;
            NSInteger visited = (NSInteger)[visitedMaxes indexOfObject:[NSNumber numberWithInteger:localResults[i]]];
            if(visited == NSNotFound){
                if(vals[localResults[i]] > localMax && hits[localResults[i]] != 0){
                    localMax = vals[localResults[i]];
                    hits[localResults[i]] = 0;
                    localMaxIndex = i;
                }
            }
        }
        
        [visitedMaxes addObject:[NSNumber numberWithInteger:lastBestIndex]];
        
        NSInteger planeLength = brushDiameter * brushDiameter;
        NSInteger localA = localMaxIndex / planeLength - brushThickness;
        NSInteger localY = (localMaxIndex % planeLength)/brushDiameter - brushThickness;
        NSInteger localX = localMaxIndex % brushDiameter - brushThickness;
        
        
        cumA += localA;
        cumX += localX;
        cumY += localY;
        
        //Check whether we have found maximum. Termination condition
        if(vals[localResults[localMaxIndex]] > vals[lastBestIndex]){
            tolerating = 0;
            lastBestIndex = localResults[localMaxIndex];
            maxima = @[
                                [NSNumber numberWithInteger:vals[localResults[localMaxIndex]]],
                                [NSNumber numberWithInteger:cumA],
                                [NSNumber numberWithInteger:cumX],
                                [NSNumber numberWithInteger:cumY],
                                ];
        }else{
            if(localMaxIndex == 13)localMaxIndex--;
            tolerating++;
        }
        
        //NSLog(@"Loc A X Y %li %li %li", localA, localX, localY);
        if(tolerating == 0){
            NSLog(@"LOCAL MAX %li (Prev %li) at local INDEX %li totalIndex %li totalComps %li", localMax, vals[lastBestIndex], localMaxIndex, localResults[localMaxIndex], totalCounter);
            NSLog(@"____Termination %li", tolerating);
            NSLog(@"Cum A X Y %li %li %li", cumA, cumX, cumY);
        }
        
        if(tolerating >= toleranceToDecrease){
            improving = NO;
        }
    }
    
    dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION] = @([dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue] + [IMCRegistration radiansToDegrees:[maxima[1]integerValue] * angleStep]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]integerValue] + [maxima[2]integerValue]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]integerValue] + [maxima[3]integerValue]);
    
    
    CFRelease(canvas);
    CGImageRef ret = CGBitmapContextCreateImage(rotCanvas);
    CFRelease(rotCanvas);
    free(oriBuffer);
    free(destBuffer);
    
    NSLog(@"Address vals %p", vals);
    *capture = *vals;
    NSLog(@"Address capture %p", capture);
    return ret;
}

+(CGImageRef)startRegistration:(NSInteger *)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep destDict:(NSMutableDictionary *)dest inelasticBrush:(NSInteger)brushIneslastic elasticBrush:(NSInteger)brushElastic exactMatches:(BOOL)exact{
    if(sourceImg == NULL || targetImg == NULL)return NULL;
    
    float max = MAX(MAX(CGImageGetWidth(sourceImg), CGImageGetHeight(sourceImg)),
                    MAX(CGImageGetWidth(targetImg), CGImageGetHeight(targetImg)));

    float subset = max * .5f;
    float halfSubset = subset/2;
    NSInteger total = (NSInteger)subset * subset;
    
    void * oriBuffer = calloc(total, sizeof(UInt8));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
    CGContextRef canvas = CGBitmapContextCreate(oriBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    CGRect frame = CGRectMake(-subset/2, -subset/2, max, max);
    CGContextDrawImage(canvas, frame, sourceImg);
    
    
    void * destBuffer = calloc(total, sizeof(UInt8));
    CGContextRef rotCanvas = CGBitmapContextCreate(destBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    
    UInt8 * bufferSource = (UInt8 *)oriBuffer;
    UInt8 * bufferDest = (UInt8 *)destBuffer;

    NSInteger toleranceToDecrease = 300;
    NSInteger tolerating = 0;
    NSInteger lastBestValue = 0;
    
    NSInteger cumA = 0;
    NSInteger cumX = 0;
    NSInteger cumY = 0;
    NSInteger cumCX = 0;
    NSInteger cumCY = 0;

    NSInteger totalCounter = 0;
    
    NSMutableArray *visited = @[].mutableCopy;
    NSArray *maxima;

    float * diffsCanvas = [self diffsArrayForArray:bufferSource length:total];
    
    //Will alternate between the elastic and inelastic components of the registration
    NSInteger temBrushInelastic = 0;
    NSInteger temBrushElastic = brushElastic;
    
    while (YES){
        temBrushInelastic = temBrushInelastic == 0?brushIneslastic:0;
        temBrushElastic = temBrushElastic == 0?brushElastic:0;
        //Except if am doing purely inelastic
        if(brushElastic == 0)temBrushInelastic = brushIneslastic;
        
        NSMutableDictionary *localResults = @{}.mutableCopy;
        
        for (NSInteger a = -temBrushInelastic; a <= temBrushInelastic; a++)
            
            for (NSInteger y = -temBrushInelastic; y <= temBrushInelastic; y++)
                
                for (NSInteger x = -temBrushInelastic; x <= temBrushInelastic; x++)
                    
                    for (NSInteger cx = -temBrushElastic; cx <= temBrushElastic; cx++)
                        
                        for (NSInteger cy = -temBrushElastic; cy <= temBrushElastic; cy++) {
                            
                            NSString *identifier = [NSString stringWithFormat:@"%li.%li.%li.%li.%li",
                                                    cumA + a,
                                                    cumX + x,
                                                    cumY + y,
                                                    cumCX + cx,
                                                    cumCY + cy];
                            
                            if(![visited containsObject:identifier])
                                [visited addObject:identifier];
                            else
                                continue;
                            
                            //Paint
                            frame = CGRectMake(-halfSubset,
                                               -halfSubset,
                                               max * (1 + .005f * (cumCX + cx)),
                                               max * (1 + .005f * (cumCY + cy))
                                               );
                            
                            [IMCRegistration clearBufferSource:bufferDest withWidth:subset];
                            
                            CGContextSaveGState(rotCanvas);
                            
                            [self transformCanvas:rotCanvas
                                            angle:(cumA + a) * angleStep
                                           xTrans:cumX + x
                                        andYtrans:cumY + y
                                   widthMidXtrans:halfSubset
                                andMidthMidYtrans:halfSubset];
                            
                            
                            CGContextDrawImage(rotCanvas, frame, targetImg);
                            CGContextRestoreGState(rotCanvas);
                            
                            totalCounter++;
                            
                            if(exact)
                                localResults[identifier] = @([IMCRegistration matchesForArrays:bufferSource withArray:bufferDest length:total]);
                            else
                                localResults[identifier] = @((NSInteger)([IMCRegistration correlationForArrayDiffs:diffsCanvas withArray:bufferDest length:total] * 1000000));
                            //localResults[identifier] = @([IMCRegistration simpleMutualInformation:bufferSource withArray:bufferDest length:total]);
                        }
        
        
        //Check best
        NSInteger maxVal = 0;
        NSString *identMaxLocal;
        for (NSString *key in localResults)
            if([localResults[key]integerValue] > maxVal){
                identMaxLocal = key;
                maxVal = [localResults[key]integerValue];
            }
            
        if(identMaxLocal){
            NSArray *idComps = [identMaxLocal componentsSeparatedByString:@"."];
            cumA += ([idComps[0]integerValue] - cumA);
            cumX += ([idComps[1]integerValue] - cumX);
            cumY += ([idComps[2]integerValue] - cumY);
            cumCX += ([idComps[3]integerValue] - cumCX);
            cumCY += ([idComps[4]integerValue] - cumCY);
        }
        NSLog(@"Cum A X Y %li %li %li %li %li TOL: %li", cumA, cumX, cumY, cumCX, cumCY, tolerating);
        //Check whether we have found maximum. Termination condition
        if(maxVal > lastBestValue){
            tolerating /= 2;
            lastBestValue = maxVal;
            maxima = @[
                       [NSNumber numberWithInteger:cumA],
                       [NSNumber numberWithInteger:cumX],
                       [NSNumber numberWithInteger:cumY],
                       [NSNumber numberWithInteger:cumCX],
                       [NSNumber numberWithInteger:cumCY],
                       ];
        }
        else
            tolerating++;
        
        if(tolerating >= toleranceToDecrease)
            break;
    }
    
    dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION] = @([dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue] + [IMCRegistration radiansToDegrees:[maxima[0]integerValue] * angleStep]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue] + [maxima[1]floatValue]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue] + [maxima[2]floatValue]);
    float prevCompX = [dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
    dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X] = @(prevCompX + (prevCompX * [maxima[3]floatValue] * .005));
    
    float prevCompY = [dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
    dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y] = @(prevCompY + (prevCompY * [maxima[4]floatValue] * .005));
    
    
    CFRelease(canvas);
    CGImageRef ret = CGBitmapContextCreateImage(rotCanvas);
    CFRelease(rotCanvas);
    free(oriBuffer);
    free(destBuffer);
    
    return ret;
}


+(CGImageRef)startRegistrationRandomWalker:(NSInteger *)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep xRange:(NSInteger)xTranslationRange yRange:(NSInteger)yTranslationRange destDict:(NSMutableDictionary *)dest inelasticBrush:(NSInteger)brushIneslastic elasticBrush:(NSInteger)brushElastic{
    if(sourceImg == NULL || targetImg == NULL)return NULL;
    
    float max = MAX(MAX(CGImageGetWidth(sourceImg), CGImageGetHeight(sourceImg)),
                    MAX(CGImageGetWidth(targetImg), CGImageGetHeight(targetImg)));
    
    float subset = max * .5f;
    NSInteger total = (NSInteger)subset * subset;
    
    void * oriBuffer = calloc(total, sizeof(UInt8));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
    CGContextRef canvas = CGBitmapContextCreate(oriBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    CGRect frame = CGRectMake(-subset/2, -subset/2, max, max);
    CGContextDrawImage(canvas, frame, sourceImg);
    
    
    void * destBuffer = calloc(total, sizeof(UInt8));
    CGContextRef rotCanvas = CGBitmapContextCreate(destBuffer, subset, subset, 8, subset, colorSpace, kCGImageAlphaNone);
    
    UInt8 * bufferSource = (UInt8 *)oriBuffer;
    UInt8 * bufferDest = (UInt8 *)destBuffer;
    
    NSInteger toleranceToDecrease = 3000;
    NSInteger tolerating = 0;
    NSInteger lastBestValue = 0;
    
    NSInteger cumA = 0;
    NSInteger cumX = 0;
    NSInteger cumY = 0;
    NSInteger cumCX = 0;
    NSInteger cumCY = 0;
    
    NSInteger totalCounter = 0;
    
    NSMutableArray *visited = @[].mutableCopy;
    NSArray *maxima;
    
    float * diffsCanvas = [self diffsArrayForArray:bufferSource length:total];
    int followVar = -1;
    int followSign = -1;
    
    while (YES){
        
        int var = followVar == -1? rand()%5 : followVar;
        int sign = followSign == -1? rand()%2 : followSign;
        if(sign == 0)sign = -1;
        
        NSInteger tA = cumA, tX = cumX, tY = cumY, tCX = cumCX, tCY = cumCY;
        
        if(var == 0)tA += sign;
        if(var == 1)tX += sign;
        if(var == 2)tY += sign;
        if(var == 3)tCX += sign;
        if(var == 4)tCY += sign;
        
        NSString *identifier = [NSString stringWithFormat:@"%li.%li.%li.%li.%li",tA,tX,tY,tCX,tCY];
        NSLog(@"Id %@", identifier);
        if(![visited containsObject:identifier])
            [visited addObject:identifier];
        else
            continue;
        
        //Only after making it through
        cumA = tA; cumX = tX; cumY = tY; cumCX = tCX; cumCY = tCY;
        
        //Paint
        frame = CGRectMake(-subset/2,
                           -subset/2,
                           max * (1 + .005f * cumCX),
                           max * (1 + .005f * cumCY)
                           );
        
        [IMCRegistration clearBufferSource:bufferDest withWidth:subset];
        
        CGContextSaveGState(rotCanvas);
        
        [self transformCanvas:rotCanvas
                        angle:cumA * angleStep
                       xTrans:cumX
                    andYtrans:cumY
               widthMidXtrans:subset/2
            andMidthMidYtrans:subset/2];
        
        CGContextDrawImage(rotCanvas, frame, targetImg);
        CGContextRestoreGState(rotCanvas);
        
        totalCounter++;
        
        NSInteger localResult = (NSInteger)([IMCRegistration correlationForArrayDiffs:diffsCanvas withArray:bufferDest length:total] * 1000000);
        
        NSLog(@"Cum A X Y %li %li %li %li %li TOL: %li", cumA, cumX, cumY, cumCX, cumCY, tolerating);
        //Check whether we have found maximum. Termination condition
        if(localResult > lastBestValue){
            followVar = var;
            followSign = sign == 1? 1 : 0;
            tolerating = 0;
            lastBestValue = localResult;
            maxima = @[
                       [NSNumber numberWithInteger:cumA],
                       [NSNumber numberWithInteger:cumX],
                       [NSNumber numberWithInteger:cumY],
                       [NSNumber numberWithInteger:cumCX],
                       [NSNumber numberWithInteger:cumCY],
                       ];
        }
        else{
            followVar = -1;
            followSign = -1;
            tolerating++;
        }
        
        if(tolerating >= toleranceToDecrease)
            break;
    }
    
    dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION] = @([dest[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue] + [IMCRegistration radiansToDegrees:[maxima[0]integerValue] * angleStep]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue] + [maxima[1]floatValue]);
    dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y] = @([dest[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue] + [maxima[2]floatValue]);
    float prevCompX = [dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
    dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X] = @(prevCompX + (prevCompX * [maxima[3]floatValue] * .005));
    
    float prevCompY = [dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
    dest[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y] = @(prevCompY + (prevCompY * [maxima[4]floatValue] * .005));
    
    
    CFRelease(canvas);
    CGImageRef ret = CGBitmapContextCreateImage(rotCanvas);
    CFRelease(rotCanvas);
    free(oriBuffer);
    free(destBuffer);
    
    return ret;
}

@end
