//
//  IMCMatlabLoader.m
//  3DIMC
//
//  Created by Raul Catena on 2/13/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_MatlabLoader.h"
#import "IMCMatLabParser.h"
#import "NSDataGZipAdditions.h"


@implementation IMC_MatlabLoader


+(BOOL)loadMatDataETHZ:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{//Mat is supposed to be 3dim miMATRIX compressed. Anything different will not work
    
    IMCMatLabParser *parser = [[IMCMatLabParser alloc]init];
    parser.matlabData = data;
    
    NSData *ole = [NSData dataWithCompressedData:[data subdataWithRange:NSMakeRange(136, [parser numberOfBytes])]];
    NSMutableData *rebuilt = [NSMutableData data];
    int b = 0;
    for (int i = 0; i < 32; i++) {
        [rebuilt appendBytes:&b length:4];
    }
    [rebuilt appendData:ole];
    parser.matlabData = rebuilt;
    
    if([parser channels] > 1000 || [parser channels] == 0)return NO;
    
    double * bytes = (double *)[parser doubleBuffer];
    
    [imageStack clearBuffers];
    
    NSMutableArray *channels = @[].mutableCopy;
    for (NSInteger i = 0; i < [parser channels]; i++) {
        [channels addObject:[NSString stringWithFormat:@"channel %li", i + 1]];
    }
    imageStack.channels = channels;
    imageStack.origChannels = channels;
    imageStack.width = [parser widthMatrix];
    imageStack.height = [parser heightMatrix];
    
    
    
    [imageStack allocateBufferWithPixels:imageStack.numberOfPixels];
    
    NSInteger numberPixels = imageStack.numberOfPixels;
    NSInteger buffLength = numberPixels * imageStack.channels.count;
    NSInteger clockPixs = 0;
    NSInteger clockChannels = 0;
    
    NSInteger col = 0;
    
    NSInteger stride = 0;
    
    for (NSInteger i = 0; i< buffLength; i++) {
        imageStack.stackData[clockChannels][stride + col] = (float)bytes[i];
        stride += imageStack.width;
        clockPixs++;
        
        if (clockPixs == numberPixels) {
            clockChannels++;
            clockPixs = 0;
            col = 0;
            stride = 0;
        }
        if(clockPixs % imageStack.height == 0){
            col++;
            stride = 0;
        }
    }
    [IMC_MatlabLoader setChannelSettingsToMult1:imageStack];
    
    return YES;
}

@end
