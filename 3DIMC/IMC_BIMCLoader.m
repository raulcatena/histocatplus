//
//  IMC_BIMCLoader.m
//  3DIMC
//
//  Created by Raul Catena on 1/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_BIMCLoader.h"

@implementation IMC_BIMCLoader

+(BOOL)loadBIMCdata:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{//2015 Standard. May have to expand
    NSLog(@"Data %li", data.length);
    //if(data.length == 127395332)return NO;
    NSDictionary *theDict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if ([theDict respondsToSelector:@selector(valueForKey:)]) {
        
        NSData *images = [theDict valueForKey:@"dataIMC"];
        imageStack.width = [[[theDict valueForKey:@"dimensions"]firstObject]intValue];
        imageStack.height = [[[theDict valueForKey:@"dimensions"]lastObject]intValue];
        
        if(!imageStack.channels || imageStack.channels.count != [[theDict valueForKey:@"channels"]count])
            imageStack.channels = [[theDict valueForKey:@"channels"]mutableCopy];
        if(!imageStack.origChannels || imageStack.origChannels.count != imageStack.channels.count)
            imageStack.origChannels = [[theDict valueForKey:@"origChannels"]mutableCopy];
        if(imageStack.origChannels.count != imageStack.channels.count)
            imageStack.channels = [imageStack.origChannels mutableCopy];
        
        imageStack.itemName = [theDict valueForKey:@"name"]?theDict[@"name"]:imageStack.fileWrapper.relativePath;
        
        int * bytes = (int *)[(NSData *)images bytes];
        [imageStack clearBuffers];
        [imageStack allocateBufferWithPixels:imageStack.numberOfPixels];
        
        NSInteger chanCount = imageStack.channels.count;
        NSInteger buffLength = imageStack.numberOfPixels * chanCount;
        NSInteger clockPixs = 0;
        NSInteger clockChannels = 0;
        for (NSInteger i = 0; i< buffLength; i++) {
            imageStack.stackData[clockChannels][clockPixs] = (float)bytes[i];
            clockChannels++;
            if(clockChannels == chanCount){
                clockChannels = 0;
                clockPixs++;
            }
        }
        return YES;
    }
    return NO;
}

+(BOOL)saveBIMCdata:(IMCImageStack *)imageStack toPath:(NSString *)path{//2015 Standard. May have to expand
    
    //Legacy saving
    
    long int size = [imageStack numberOfPixels] * imageStack.channels.count;
    NSMutableData *dataBin = [NSMutableData dataWithCapacity:size * sizeof(int)];
    NSInteger channelsCount = imageStack.channels.count;
    for (int i = 0; i<size; i++) {
        int val = (int)imageStack.stackData[i%channelsCount][i/channelsCount];
        [dataBin appendBytes:&val length:sizeof(int)];
    }
    
    NSDictionary *dict = @{
                           @"dataIMC":dataBin,
                           @"dimensions":@[[NSNumber numberWithInteger:imageStack.width], [NSNumber numberWithInteger:imageStack.height]],
                           @"channels":imageStack.channels,
                           @"name":imageStack.itemName?imageStack.itemName:@"UnknownFileName",
                           @"origChannels": imageStack.origChannels,
                           };
    
    
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    if(!data)return NO;
    
    NSError *error = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    if(error){
        NSLog(@"Write returned error: %@", [error localizedDescription]);
        return NO;
    }
    return YES;
}

@end
