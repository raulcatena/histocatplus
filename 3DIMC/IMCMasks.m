//
//  IMCMasks.m
//  IMCReader
//
//  Created by Raul Catena on 12/10/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "IMCMasks.h"
#import "IMCMatLabParser.h"
#import "IMCImageStack.h"

@implementation IMCMasks


void transformImageSegmentationResultTo0and255(int * buffer, NSInteger width, NSInteger height){
    for (int i = 0; i<width * height; i++) {
        if (buffer[i] == 255) {
            buffer[i] = 0;
        }
        if (buffer[i] == -1) {
            buffer[i] = 1;
        }
    }
}

+(void)flattenMask:(int *)mask width:(NSInteger)width height:(NSInteger)height{
    NSInteger size = width * height;
    for (NSInteger i = 0; i < size; i++)
        if(mask[i] > 1)
            mask[i] = 1;
}

//+(int *)produceIDedMask:(int *)mask width:(NSInteger)width height:(NSInteger)height{
//    
//    int * newMask = calloc(width * height, sizeof(int));
//    transformImageSegmentationResultTo0and255(mask, width, height);//from imageJ comes this funny
//    for (int i = 0; i < width * height; i++) {
//        newMask[i] = mask[i];
//    }
//    
//    int counter = 2;
//    for (int i = 0;i < width * height; i++) {//I will run through all pixels of image
//        
//        if (newMask[i] == 1) {//Non-reindexed pixel
//            
//            newMask[i] = counter;//Asign seed to this pixel
//            
//            BOOL found = YES;//To limit looping
//            for (int l = 1; l<100; l++) {//I give a max of 10 layers, although I'll make this dynamic
//                if(found == NO)break;
//                else found = NO;
//                for (int j = -l; j< l+1; j++) {// X Loop
//                    
//                    for (int k = -l; k<l+1; k++) {//Y Loop
//                        
//                        NSInteger ind = i - j * width + k;//Grab de index of analyzed pixel
//                        
//                        if(ind >=0 && ind < width * height && ind != i){//Index in bounds of image
//                            
//                            if(newMask[ind] == 1){//Potential neighbour not modified yet
//                                NSInteger upInd = ind - width;
//                                NSInteger downInd = ind + width;
//                                NSInteger leftInd = ind - 1;
//                                NSInteger rightInd = ind +1;
//                                
//                                if(upInd > 0 && upInd < width * height && rightInd != ind){
//                                    if(newMask[upInd] == counter){
//                                        found = YES;
//                                        newMask[ind] = counter;
//                                        continue;
//                                    }
//                                }
//                                if(downInd > 0 && downInd < width * height && rightInd != ind){
//                                    if(newMask[downInd] == counter){
//                                        found = YES;
//                                        newMask[ind] = counter;
//                                        continue;
//                                    }
//                                }
//                                if(leftInd > 0 && leftInd < width * height && rightInd != ind){
//                                    if(newMask[leftInd] == counter){
//                                        found = YES;
//                                        newMask[ind] = counter;
//                                        continue;
//                                    }
//                                }
//                                if(rightInd > 0 && rightInd < width * height && rightInd != ind){
//                                    if(newMask[rightInd] == counter){
//                                        found = YES;
//                                        newMask[ind] = counter;
//                                        continue;
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            
//            counter++;//Prepare next seed to this pixel
//        }
//    }
//    for (int i = 0; i < width * height; i++) {
//        //printf("%i ", newMask[i]);
//    }
//    return newMask;
//}

+(int *)produceIDedMask:(int *)mask width:(NSInteger)width height:(NSInteger)height destroyOrigin:(BOOL)destroy{//Slow algorithm
    
    NSInteger totalPixels = width * height;
    int * newMask = calloc(totalPixels, sizeof(int));
    transformImageSegmentationResultTo0and255(mask, width, height);//from imageJ comes this funny
    for (int i = 0; i < totalPixels; i++) {
        newMask[i] = -mask[i];
    }
    
    int counter = 1;
    for (int i = 0; i < totalPixels; i++) {//I will run through all pixels of image
        
        if (newMask[i] == -1) {//Non-reindexed pixel
            newMask[i] = counter;//Asign seed to this pixel
            NSMutableArray *arr = @[].mutableCopy;
            NSNumber *inScopeNumber = @(i);
            do{
                NSInteger candidates[4] = {inScopeNumber.integerValue - width,
                                            inScopeNumber.integerValue + width,
                                            inScopeNumber.integerValue - 1,
                                            inScopeNumber.integerValue + 1,
                                            };
                for (int m = 0; m < 4;  m++){
                    if(candidates[m] > 0 && candidates[m] < totalPixels)
                        if(newMask[candidates[m]] == -1){
                            newMask[candidates[m]] = counter;
                            [arr addObject:@(candidates[m])];
                        }
                }
                
                inScopeNumber = [arr lastObject];
                [arr removeLastObject];
            }
            while (inScopeNumber);
            counter++;//Prepare next seed to this pixel
        }
    }
    
    if(destroy)
        free(mask);
    
    return newMask;
}


void increaseMaskBoundsBy(int layer, int *mask, int width, int height){
    
    NSInteger total = width * height;
    for (int x = 0; x < layer; x++) {
        
        for (int i = 0;i < width * height; i++) {
            
            if (mask[i] > 0) {
                for (int j = -layer; j < layer + 1; j++) {
                    for (int k = -layer; k < layer + 1; k++) {
                        int index =  i + width * j + k;
                        if (doesNotJumpLine(i, index, width, height, total, layer)) {
                            if (mask[index] == 0 ) {
                                mask[index] = -mask[i];
                            }
                        }
                    }
                }
            }
        }
    }
    for (int i = 0;i < width * height; i++) {
        if (mask[i] < 0) {
            mask[i] = -mask[i];
        }
    }
}

void increaseMaskBoundsNegBy(int layer, int *mask, int width, int height){
    
    NSInteger total = width * height;
    for (int x = 0; x < layer; x++) {
        
        for (int i = 0;i < width * height; i++) {
            
            if (mask[i] > 0) {
                for (int j = -layer; j < layer + 1; j++) {
                    for (int k = -layer; k < layer + 1; k++) {
                        int index =  i + width * j + k;
                        if (doesNotJumpLine(i, index, width, height, total, layer)) {
                            if (mask[index] == 0 ) {
                                mask[index] = -mask[i];
                            }
                        }
                    }
                }
            }
        }
    }
}

int * copyMask(int *mask, int width, int height){
    int * copy = calloc(width * height, sizeof(int));
    NSInteger size = width * height;
    for (int i = 0; i < size; i++)
        copy[i] = mask[i];
    return copy;
}

UInt8 * copyMask8bit(UInt8 *mask, NSInteger width, NSInteger height){
    UInt8 * copy = calloc(width * height, sizeof(UInt8));
    for (int i = 0;i < width * height; i++)
        copy[i] = mask[i];
    return copy;
}
-(NSDictionary *)extractValuesForMask:(int *)mask forChannelData:(int *)channelData width:(int)width height:(int)height channels:(NSArray *)channels{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}
int * cMaskFromObjectMask(NSArray *mask){
    int * cMask = calloc(mask.count, sizeof(int));
    NSInteger cursor = 0;
    for(NSNumber *num in mask){
        cMask[cursor] = num.intValue;
        cursor++;
    }
    return cMask;
}
void invertMask(int *mask, int width, int height){
    NSInteger size = width * height;
    for (NSInteger i = 0; i < size; i++) {
        if(mask[i] > 0)mask[i] = 0;
        else mask[i] = 1;
    }
}
+(int *)invertMaskCopy:(int *)mask size:(NSInteger)size{
    int * new = calloc(size, sizeof(int));
    for (NSInteger i = 0; i < size; i++) {
        if(mask[i] > 0)
            new[i] = 0;
        else
            new[i] = 1;
    }
    return new;
}

+(int *)extractFromMask:(int *)mask1 withMask:(int *)mask2 width:(NSInteger)width height:(NSInteger)height tolerance:(float)tolerance exclude:(BOOL)exclude filterLabel:(NSInteger)filterLabel{
    
    NSInteger max = 0;
    NSInteger size = width * height;
    for (NSInteger i = 0; i < size; i++)
        if(mask1[i] > max)
            max = mask1[i];
    
    int * result = calloc(size, sizeof(int));
    float * countYes = calloc(max, sizeof(float));
    float * countNo = calloc(max, sizeof(float));
    int * selected = calloc(max, sizeof(int));
    
    for (NSInteger i = 0; i < size; i++)
        if(filterLabel == NSNotFound){
            if(abs(mask1[i]) > 0 && abs(mask2[i]) > 0)
                countYes[abs(mask1[i])]++;
            else
                countNo[abs(mask1[i])]++;
        }else{
            if(abs(mask1[i]) > 0 && abs(mask2[i]) == filterLabel)
                countYes[abs(mask1[i])]++;
            else
                countNo[abs(mask1[i])]++;
        }
    
    for (int i = 0; i < max; i++)
        if(countNo[i]/countYes[i] < tolerance)
            selected[i] = exclude?0:1;
        else
            selected[i] = exclude?1:0;
    
    for (NSInteger i = 0; i < size; i++)
        if(selected[abs(mask1[i])] > 0)
            result[i] = abs(mask1[i]);

    return result;
}

-(int *)produceMultiColorMask:(int *)mask width:(int)width height:(int)height{
    int * newMask = calloc(width * height, sizeof(int));
    for (int i = 0; i<width * height; i++) {
        if(mask[i] != 0)newMask[i] = MAX(mask[i]%17, 1);
    }
    return newMask;
}

float distanceFromPointAToXAndYWidhWidth(NSInteger indexA, float x, float y, NSInteger width){
    float calcDist = sqrtf(pow(x - (indexA + width)%width, 2) + pow(y - indexA/width, 2));
    return calcDist;
}

+(float *)distanceToMasks:(float *)xCentroids yCentroids:(float *)yCentroids destMask:(int *)maskDestination max:(NSInteger)max width:(NSInteger)width height:(NSInteger)height filterLabel:(NSInteger)filterLabel{
    
    float *results = calloc(max, sizeof(float));
    NSInteger total = width * height;
    float bounds = sqrt(width * width + height * height)/2;
    for (NSInteger i = 0; i < max; i++) {
        //printf("cell %li of %li\n", (long)i, (long)max);
        NSInteger index = (NSInteger)xCentroids[i] + width * (NSInteger)yCentroids[i];
        
        BOOL found = NO;
        int distance = 1;
        while (found == NO) {
            if (distance > bounds) {
                break;
            }
            NSInteger foundIndex = -1;
            //First loop
            // XXXXXXX
            // ------- x 5
            // XXXXXXX
            for (int x = -distance; x < distance + 1; x++) {
                for (int y = -distance; y < distance+1; y+= 2 * distance) {
                    NSInteger indexTest = index + x + y * width;
                    if(doesNotJumpLine(index, indexTest, width, height, total, distance) == YES){
                        if(filterLabel == NSNotFound){
                            if (maskDestination[indexTest] != 0) {
                                foundIndex = indexTest;
                                break;
                            }
                        }else{
                            if (maskDestination[indexTest] == filterLabel) {
                                foundIndex = indexTest;
                                break;
                            }
                        }
                    }
                }
                if(foundIndex >= 0)break;
            }
            //Second loop
            // -------
            // X-----X x 5
            // -------
            if (foundIndex == -1) {
                for (int x = -distance; x < distance + 1; x+= 2 * distance) {
                    for (int y = -(distance - 1); y < distance; y++) {
                        NSInteger indexTest = index + x + y * width;
                        if(doesNotJumpLine(index, indexTest, width, height, total, distance) == YES){
                            if(filterLabel == NSNotFound){
                                if (maskDestination[indexTest] != 0) {
                                    foundIndex = indexTest;
                                    break;
                                }
                            }else{
                                if (maskDestination[indexTest] == filterLabel) {
                                    foundIndex = indexTest;
                                    break;
                                }
                            }
                        }
                    }
                    if(foundIndex >= 0)break;
                }
            }
            
            if(foundIndex >= 0){
                results[i] = distanceFromPointAToXAndYWidhWidth(foundIndex, xCentroids[i], yCentroids[i], width);
                found = YES;
                break;
            }
            
            distance++;
        }
    }
    
    return results;
}
+(void)invertToProximity:(float *)distances cells:(NSInteger)cells{
    float maxDistace = 0;
    for (NSInteger i = 0; i < cells; i++) {
        float ab = fabsf(distances[i]);
        if (ab > maxDistace) {
            maxDistace = ab;
        }
    }
    for (NSInteger i = 0; i < cells; i++) {
        distances[i] = fabsf(distances[i] - maxDistace);
    }
}
+(void)idMask:(int *)extracted target:(int *)target size:(CGSize)size{
    NSInteger total = (NSInteger)(size.width * size.height);
    NSInteger width = (NSInteger)size.width;
    NSInteger heigth = (NSInteger)size.height;
    for (NSInteger i = 0; i < total; i++)
        if(extracted[i] != 0){
            if(target[i] != 0){
                extracted[i] = target[i];
            }else{
                BOOL found = NO;
                int distance = 0;
                while (!found) {
                    distance++;
                    for (int x = - distance; x < distance + 1; x++)
                        for (int y = - distance; y < distance + 1; y++){
                            NSInteger ind = i - y * width + x;
                            if(doesNotJumpLine(i, ind, width, heigth, total, distance)){
                                if(target[ind] != 0){
                                    extracted[i] = target[ind];
                                    found = YES;
                                }
                            }
                        }
                }
            }
        }
}

+(int *)maskFromFile:(NSURL *)url forImageStack:(IMCImageStack *)stack{
    
    NSInteger totalSize = [stack numberOfPixels];
    if ([[url.absoluteString pathExtension]isEqualToString:EXTENSION_TIFF] || [[url.absoluteString pathExtension]isEqualToString:EXTENSION_TIF]) {

        NSImage *image = [[NSImage alloc]initWithData:[NSData dataWithContentsOfFile:url.path]];
        if(image){
            NSBitmapImageRep *rep = (NSBitmapImageRep *)image.representations.firstObject;
            
            int *res = calloc(totalSize, sizeof(int));
            
            NSInteger bits = rep.bitsPerPixel;
            NSLog(@"%li", bits);
            if(bits == 16){
                UInt16 *data = (UInt16 *)[rep bitmapData];
                for (NSInteger i = 0; i < totalSize; i++)
                    res[i] = data[i];
            }else if(bits == 8){
                UInt8 *data = (UInt8 *)[rep bitmapData];
                for (NSInteger i = 0; i < totalSize; i++)
                    res[i] = data[i];
            }else if(bits == 32){
                UInt32 *data = (UInt32 *)[rep bitmapData];
                for (NSInteger i = 0; i < totalSize; i++)
                    res[i] = data[i];
            }
            
            return res;
        }
        
        
//        NSData *data = [NSData dataWithContentsOfURL:url];
//        NSImage *image = [[NSImage alloc]initWithData:data];
//        if(image.size.width == stack.width && image.size.height == stack.height){
//            NSInteger start = data.length%(NSInteger)(image.size.width * image.size.height);
//            short *buff = (short *)[data bytes];
//            
//            int *res = calloc(data.length - start/2, sizeof(int));
//            
//            int cursor = 0;
//            for (NSUInteger i = start/2; i < data.length; i+=2) {
//                res[cursor] = buff[i];
//                cursor++;
//                if (cursor == totalSize)break;
//            }
//            free(buff);
//            return res;
//        }
    }
    
    NSLog(@"URL is %@", url);
    
    if ([[url.absoluteString pathExtension]isEqualToString:EXTENSION_M32]) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSInteger lenght = stack.numberOfPixels;
        int * res = calloc(lenght, sizeof(int));
        int val;
        
        for (NSInteger i = 0; i < lenght; i++ ) {
            [data getBytes:&val range:NSMakeRange(i * sizeof(int), sizeof(int))];
            res[i] = val;
        }
        return res;
    }
    
    if ([[url.absoluteString pathExtension]isEqualToString:EXTENSION_MAT]) {
        
        NSData *data = [NSData dataWithContentsOfURL:url];
        IMCMatLabParser *parser = [[IMCMatLabParser alloc]init];
        parser.matlabData = data;
        
        if([parser dataType] == 14){
        
            NSInteger width = [parser widthMatrix];
            NSInteger height = [parser heightMatrix];
            
            if(width == stack.width && height == stack.height){
                
                int * res = calloc(stack.numberOfPixels, sizeof(int));
                NSInteger row = 0, column = 0;
                NSInteger total = stack.numberOfPixels;
                size_t byteType = round((float)data.length/total);
                
                if(byteType == 1){
                    char * buff = [parser charBuffer];
                    for (NSInteger i = 0; i < total; i++) {
                        res[row * width + column] = buff[i];
                        row++;
                        if(row == height){
                            row = 0;
                            column++;
                        }
                    }
                }
                if(byteType == 2){
                    short * buff = [parser shortBuffer];
                    for (NSInteger i = 0; i < total; i++) {
                        res[row * width + column] = buff[i];
                        row++;
                        if(row == height){
                            row = 0;
                            column++;
                        }
                    }
                }
                if(byteType == 4){
                    int * buff = [parser intBuffer];
                    for (NSInteger i = 0; i < total; i++) {
                        res[row * width + column] = buff[i];
                        row++;
                        if(row == height){
                            row = 0;
                            column++;
                        }
                    }
                }
                return res;
            }
        }
    }
    return NULL;
}

void bordersOnlyMask(int * mask, NSInteger width, NSInteger height){
    int * newMask = calloc(width * height, sizeof(int));
    NSInteger total = width * height;
    for (int i = 0;i < width * height; i++) {
        if (mask[i] > 0) {
            
            for (NSInteger j = i - width - 1; j< i - width + 2; j++) {
                for (NSInteger k = 0; k<3; k++) {
                    NSInteger l = j + width * k;
                    if (doesNotJumpLine(i, l, width, height, total, 3)) {
                        if (mask[l] == 0 || mask[l] != mask[i]) {
                            newMask[i] = mask[i];
                        }
                    }
                }
            }
            
        }
    }
    for (int i = 0;i < width * height; i++) {
        mask[i] = newMask[i];
    }
    free(newMask);
}

void noBordersMask(int * mask, NSInteger width, NSInteger height){
    int * newMask = calloc(width * height, sizeof(int));
    NSInteger total = width * height;
    for (NSInteger i = 0; i<width * height; i++) {
        if(mask[i] != 0){
            newMask[i] = mask[i];//MAX(mask[i]%17, 1);
            for (NSInteger j = i - width - 1; j< i - width + 2; j++) {
                for (NSInteger k = 0; k<3; k++) {
                    NSInteger l = j + width * k;
                    if (doesNotJumpLine(i, l, width, height, total, 3)) {
                        if (mask[l] != 0 && abs(mask[l]) != abs(mask[i])) {
                            newMask[i] = 0;
                        }
                    }
                }
            }
        }
    }
    for (int i = 0;i < width * height; i++) {
        mask[i] = newMask[i];
    }
    free(newMask);
}

BOOL doesNotJumpLine(NSInteger index, NSInteger indexTest, NSInteger width, NSInteger height, NSInteger total, NSInteger expectedDistance){
    if(indexTest>=total || indexTest < 0)return NO;
    if(labs((indexTest+width)%width - (index+width)%width) > expectedDistance)return NO;
    if(indexTest != index && indexTest >= 0 && indexTest < total)
        return YES;
    return NO;
}

@end
