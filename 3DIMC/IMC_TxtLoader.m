//
//  IMC_TxtLoader.m
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_TxtLoader.h"

@interface IMC_TxtLoader()

@end

@implementation IMC_TxtLoader

+(BOOL)fluidigmCoords:(IMCImageStack *)imageStack fileLines:(NSUInteger)fileLines{
    
    int whatX = (int)[imageStack.channels indexOfObject:@"X"];
    int width = 0;

    float ** data = imageStack.stackData;
    NSInteger maxPixToAnalyze = MIN(20000, fileLines);
    for (int pix = 0; pix < maxPixToAnalyze; pix++)//Beware, will fail if image is bigger than 10 mm wide. Don't think so}
        width = MAX(width, data[whatX][pix]);


    if(width <= 0)
        return NO;
    width++;
    imageStack.width = width;
    imageStack.height = fileLines/width;
    return YES;
}

+(BOOL)checkTXTMCDFile:(IMCImageStack *)imageStack fileLines:(NSUInteger)fileLines{
    
    if ([imageStack.channels containsObject:@"X"] && [imageStack.channels containsObject:@"Y"]) {
    
        return [IMC_TxtLoader fluidigmCoords:imageStack fileLines:fileLines];
    }
    return NO;
}

+(BOOL)loadTXTDataOld:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{
    
    static NSData* returnCodeData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static const uint8_t magicReturn[] = { 0x0d, 0x0a };//Code for return \n
        returnCodeData = [NSData dataWithBytesNoCopy:(void*)magicReturn length:2 freeWhenDone:NO];
    });
    
    static NSData* spaceCodeData = nil;
    static dispatch_once_t onceTokenB;
    dispatch_once(&onceTokenB, ^{
        static const uint8_t magicSpace[] = { 0x09 };//Code for space
        spaceCodeData = [NSData dataWithBytesNoCopy:(void*)magicSpace length:1 freeWhenDone:NO];
    });

    NSRange range = [data rangeOfData:returnCodeData options:0 range:NSMakeRange(0, [data length])];

    if (range.location != NSNotFound) {
        NSData* subdataHeader = [data subdataWithRange:NSMakeRange(0, range.location)];
        imageStack.channels = [[[[NSString alloc]initWithData:subdataHeader encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"\t"]mutableCopy];
        imageStack.origChannels = imageStack.channels.copy;
        
    }else{
        return NO;
    }
    NSUInteger fileLines = 0;
    NSRange movingRange = NSMakeRange(range.location, 0);
    do {
        movingRange = [data rangeOfData:returnCodeData options:0 range:NSMakeRange(movingRange.location + 2, MIN(range.location, data.length - movingRange.location))];
        fileLines++;
    } while (movingRange.location != NSNotFound && movingRange.location < data.length - MIN(range.location, data.length - movingRange.location));
    
    NSLog(@"The number of lines are %lu Cursor stoped at %@", (unsigned long)fileLines, NSStringFromRange(movingRange));
    
    NSUInteger upperLoc = 0;
    NSUInteger lowerLoc = 0;
    NSString *string = nil;
    NSRange cursor = NSMakeRange(range.location, 30);
    
    int clock = 0;
    NSUInteger pix = 0;
    
    [imageStack clearBuffers];
    [imageStack allocateBufferWithPixels:fileLines];
    
    NSUInteger count = imageStack.channels.count;
    
    do {
        if(clock == imageStack.channels.count){
            clock = 0;
            pix++;
        }
        
        lowerLoc = cursor.location;
        cursor = NSMakeRange(cursor.location + 1, 30);
        
        if (clock == count - 1) {
            cursor = [data rangeOfData:returnCodeData options:0 range:cursor];
        }else cursor = [data rangeOfData:spaceCodeData options:0 range:cursor];
        
        if (cursor.location == NSNotFound) {
            break;
        }
        
        upperLoc = cursor.location;
        
        string = [[[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(lowerLoc, upperLoc - lowerLoc)] encoding:NSUTF8StringEncoding]substringFromIndex:1];
        imageStack.stackData[clock][pix] = string.floatValue;
        
        clock++;
    } while (cursor.location != NSNotFound && cursor.location + 30 < (data.length - range.location));
    
    [IMC_TxtLoader checkTXTMCDFile:imageStack fileLines:fileLines];
    //[IMCLoader notifyLoad:theImageModel];
    return YES;
}

+(BOOL)loadTXTDataOld2:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{
    NSArray *lines = [[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]componentsSeparatedByString:@"\n"];
    imageStack.channels = [[lines.firstObject componentsSeparatedByString:@"\t"]mutableCopy];
    imageStack.origChannels = imageStack.channels.copy;
    
    [imageStack clearBuffers];
    [imageStack allocateBufferWithPixels:lines.count - 1];
    
    NSUInteger count = imageStack.channels.count;
    
    for (NSInteger i = 1; i < lines.count - 1; i++) {
        NSArray *values = [lines[i] componentsSeparatedByString:@"\t"];
        for (int j = 0; j < count; j++) {
            imageStack.stackData[j][i - 1] = [values[j]floatValue];
        }
    }
    
    [IMC_TxtLoader checkTXTMCDFile:imageStack fileLines:lines.count - 1];
    //[IMCLoader notifyLoad:theImageModel];
    return YES;
}

+(BOOL)loadTXTData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{
    
//    char *buff = "this is a test string";
//    printf("%.*s", 4, buff + 10);
    NSLog(@"----");
    const char * bytes = (const char *)data.bytes;
    NSInteger lenght = data.length;
    
    NSInteger i = 0;
    NSInteger lines = 0;
    NSInteger endOfHeader = 0;
    NSInteger lineCursor = 0;
    
    bool nReturnOnly = NO;
    
    for (; i < lenght; i++) {
        if(bytes[i] == 0x0d){
            if (bytes[i + 1] == 0x0a) {
                if(endOfHeader == 0)
                    endOfHeader = i;
                else
                    lines ++;
                lineCursor = i;
            }
        }
    }
    // Just in case return is just \n
    if(endOfHeader == 0){
        i = 0;
        for (; i < lenght; i++) {
            if (bytes[i] == 0x0a) {
                if(endOfHeader == 0)
                    endOfHeader = i;
                else
                    lines++;
                lineCursor = i;
            }
        }
        if (endOfHeader != 0)
            nReturnOnly = YES;
    }

    NSString *achannels = [[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(0, endOfHeader)] encoding:NSUTF8StringEncoding];
    NSArray *channs = [achannels componentsSeparatedByString:@"\t"];
    
    if(!imageStack.channels || imageStack.channels.count != channs.count)
            imageStack.channels = channs.mutableCopy;
    if(!imageStack.origChannels || imageStack.origChannels.count != channs.count)
        imageStack.origChannels = imageStack.channels.mutableCopy;
    
    [imageStack clearBuffers];
    [imageStack allocateBufferWithPixels:lines];
        
    NSInteger pix = 0;
    NSInteger chan = 0;
    i = endOfHeader;
    NSInteger lastIndex = i;
    
    if(nReturnOnly){
        for (; i < lineCursor; i++) {
            if(bytes[i] == 0x09){//Between numbers
                imageStack.stackData[chan][pix] = atof(&bytes[lastIndex]);
                lastIndex = i;
                chan++;
            }
            if (bytes[i] == 0x0a) {
                imageStack.stackData[chan][pix] = atof(&bytes[lastIndex]);
                lastIndex = i + 1;
                chan = 0;
                pix++;
            }
            if(lastIndex + 4 >= lineCursor || pix >= lines)
                break;
        }
    }else{
        for (; i < lineCursor; i++) {
            if(bytes[i] == 0x09){//Between numbers
                imageStack.stackData[chan][pix] = atof(&bytes[lastIndex]);
                lastIndex = i;
                chan++;
            }
            if(bytes[i] == 0x0d){
                if (bytes[i + 1] == 0x0a) {
                    imageStack.stackData[chan][pix] = atof(&bytes[lastIndex]);
                    lastIndex = i + 1;
                    chan = 0;
                    pix++;
                }
            }
            if(lastIndex + 4 >= lineCursor || pix >= lines)
                break;
        }
    }
    NSLog(@"----");
    return [IMC_TxtLoader checkTXTMCDFile:imageStack fileLines:lines];
}

@end
