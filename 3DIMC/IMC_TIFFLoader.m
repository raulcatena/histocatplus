//
//  IMC_TIFFLoader.m
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_TIFFLoader.h"
#import "NSTiffSplitter.h"

@implementation IMC_TIFFLoader



+(void)processRep:(NSBitmapImageRep *)rep toIMCImageStack:(IMCImageStack *)imageStack toIndexChannel:(NSInteger)indexChannel{
    
    NSInteger lengthImage = imageStack.numberOfPixels;
    
    int channelBytes = (int)rep.bitsPerSample/8;
    
    if(channelBytes == 1 && rep.bitsPerPixel == 8){//8bit Gray
        
        UInt8 *data = (UInt8 *)[rep bitmapData];
        int chanThisImage = (int)rep.bitsPerPixel/rep.bitsPerSample;
        for (int c = 0; c < chanThisImage; c++)
            for (int j = 0; j < lengthImage; j++)
                imageStack.stackData[indexChannel][j] = (float)data[j * chanThisImage + c];
        
    }else if(channelBytes == 1 && rep.bitsPerPixel > 8){//RGB or RGBA or ABGR.../////TODO handle this case
        
        UInt8 *data = (UInt8 *)[rep bitmapData];
        int chanThisImage = (int)rep.bitsPerPixel/rep.bitsPerSample;
        
        [imageStack clearBuffers];
        if(!imageStack.channels || imageStack.channels.count != chanThisImage){
            [imageStack.channels removeAllObjects];
            for (int l = 0; l < chanThisImage; l++)
                [imageStack.channels addObject:[NSString stringWithFormat:@"Channel %i", l + 1]];
        }
        if(!imageStack.origChannels || imageStack.origChannels.count != chanThisImage)
            imageStack.origChannels = imageStack.channels.mutableCopy;
        
        [imageStack allocateBufferWithPixels:imageStack.numberOfPixels];
        
        for (int c = 0; c < chanThisImage; c++)
            for (int j = 0; j < lengthImage; j++)
                imageStack.stackData[c][j] = (float)data[j * chanThisImage + c];

    }else if(channelBytes == 2){//16bit Gray
        
        UInt16 *data = (UInt16 *)[rep bitmapData];
        int chanThisImage = (int)rep.bitsPerPixel/rep.bitsPerSample;
        for (int c = 0; c < chanThisImage; c++)
            for (int j = 0; j < lengthImage; j++)
                imageStack.stackData[indexChannel][j] = (float)data[j * chanThisImage + c];
        
    }else{//Floating point Gray
        
        float *data = (float *)[rep bitmapData];
        int chanThisImage = (int)rep.bitsPerPixel/rep.bitsPerSample;
        
        for (int c = 0; c < chanThisImage; c++)
            for (int j = 0; j < lengthImage; j++)
                imageStack.stackData[indexChannel][j] = (float)data[j * chanThisImage + c];
    }
}

+(BOOL)loadNonTIFFData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{
    
    NSImage *image = [[NSImage alloc]initWithData:data];
    NSBitmapImageRep *rep = (NSBitmapImageRep *)image.representations.firstObject;
    
    
    if(!rep)
        return NO;
    
    //---TODO Refactor
    imageStack.width = rep.pixelsWide;
    imageStack.height = rep.pixelsHigh;
    
    NSInteger channels = 0;
    channels += rep.bitsPerPixel/rep.bitsPerSample;
    NSMutableArray *channs = @[].mutableCopy;
    for (NSInteger i = 0; i < channels; i++) {
        [channs addObject:[NSString stringWithFormat:@"%li", i + 1]];
    }
    if(!imageStack.channels || imageStack.channels.count != channs.count)
        imageStack.channels = channs;
    if(!imageStack.origChannels || imageStack.origChannels.count != channs.count)
        imageStack.origChannels = channs.mutableCopy;
    
    [imageStack clearBuffers];
    [imageStack allocateBufferWithPixels:imageStack.numberOfPixels];
    //---TODO End Refactor
    
    [IMC_TIFFLoader processRep:rep toIMCImageStack:imageStack toIndexChannel:0];
    [IMC_TIFFLoader setChannelSettingsToMult1:imageStack];
    
    return YES;
}

+(BOOL)loadTIFFData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack{
    
    
    NSTiffSplitter *splitter = [[NSTiffSplitter alloc]initWithData:data];
    NSMutableArray *channs = [NSMutableArray arrayWithCapacity:splitter.countOfImages];
                       
    if(splitter.countOfImages > 0){
        int channels = 0;
        NSInteger initialWidth = 0;
        NSInteger initialHeight = 0;
        
        NSMutableArray *images = [NSMutableArray arrayWithCapacity:splitter.countOfImages];//I case they are all ARGB
        
        for (NSInteger i = 0; i < splitter.countOfImages; i++) {
            NSData *data = [splitter dataForImage:i];
            NSImage *im = [[NSImage alloc]initWithData:data];
            NSBitmapImageRep *rep = (NSBitmapImageRep *)im.representations.firstObject;
            NSString *nameImage270 = [splitter titleForImage_270:splitter index:(int)i];
            if(nameImage270)[channs addObject:nameImage270];
            else [channs addObject:[NSString stringWithFormat:@"%li", i + 1]];
            
            if(initialWidth == 0)initialWidth = rep.pixelsWide;
            else{
                if(initialWidth != rep.pixelsWide)return NO;
            }
            if(initialHeight == 0)initialHeight = rep.pixelsHigh;
            else{
                if(initialHeight != rep.pixelsHigh)return NO;
            }
            channels += rep.bitsPerPixel/rep.bitsPerSample;
            [images addObject:rep];
        }
        
        imageStack.width = initialWidth;
        imageStack.height = initialHeight;
        
        if(!imageStack.channels || imageStack.channels.count != channs.count)
            imageStack.channels = channs;
        if(!imageStack.origChannels || imageStack.origChannels.count != channs.count)
            imageStack.origChannels = channs.mutableCopy;
        
        [imageStack clearBuffers];
        [imageStack allocateBufferWithPixels:imageStack.numberOfPixels];
        
        
        for (NSBitmapImageRep *rep in images) {
            NSInteger indexChannel = [images indexOfObject:rep];
            [IMC_TIFFLoader processRep:rep toIMCImageStack:imageStack toIndexChannel:indexChannel];
        }
        
        return YES;
    }
    return NO;
}

@end
