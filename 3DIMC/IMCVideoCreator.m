//
//  IMCVideoCreator.m
//  IMCReader
//
//  Created by Raul Catena on 2/5/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCVideoCreator.h"

@implementation IMCVideoCreator


+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image),
                                  CGImageGetHeight(image));
    NSDictionary *options =
    [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGImageCompatibilityKey,
     [NSNumber numberWithBool:YES],
     kCVPixelBufferCGBitmapContextCompatibilityKey,
     nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status =
    CVPixelBufferCreate(
                        kCFAllocatorDefault, frameSize.width, frameSize.height,
                        kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
                                                 pxdata, frameSize.width, frameSize.height,
                                                 8, CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGBitmapByteOrder32Big |
                                                 kCGImageAlphaPremultipliedFirst);//It was kCGBitmapByteOrder32Little but the buffer from the CGImageRef had inverted byte order
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    
//    UInt8 *conv = (UInt8 *)pxdata;
////    NSInteger count = 0;
////    for (NSInteger i = 3; i < frameSize.width * frameSize.height * 4; i+=4) {
////        if(conv[i] > 0)
////            count++;
////    }
////    NSLog(@"%li positive", count);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

+(void)invertARGBImageFromRGBAImage:(CGImageRef)image
{
    //    CGColorSpaceRef sp = CGImageGetColorSpace(image);
    //    NSLog(@"type %i", CGColorSpaceGetModel(sp));
    CGSize dimensions = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
    UInt8 * buf = (UInt8 *) CFDataGetBytePtr(rawData);
    
    
    for(int i=0; i<dimensions.width * dimensions.height * 4; i+=4)
    {
        int r = buf[i];
        int g = buf[i+1];
        int b = buf[i+2];
        int a = buf[i+3];
        //if(i < 1000)printf("%i %i %i %i\n", r, g, b, a);
        buf[i + 1] = r;
        buf[i + 2] = g;
        buf[i + 3] = b;
        buf[i] = a;
        //if(i < 1000)printf("-%i %i %i %i\n", buf[i], buf[i + 1], buf[i + 2], buf[i + 3]);
    }
    //CFRelease(rawData);
}

+(void)writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecAppleProRes4444, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                         outputSettings:videoSettings];
    
    writerInput.expectsMediaDataInRealTime = YES;
    
    NSDictionary* bufferAttributes=[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,nil];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:bufferAttributes];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    
    CVPixelBufferRef buffer = NULL;
    
    CGImageRef ref = (__bridge CGImageRef)[array objectAtIndex:0];
    
    buffer = [IMCVideoCreator pixelBufferFromCGImage:ref];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    
    for (int i = 1; i < array.count; i++) {
        CMTime lastTime=CMTimeMake(i, duration);
        ref = (__bridge CGImageRef)array[i];
        buffer = [IMCVideoCreator pixelBufferFromCGImage:ref];
        [adaptor appendPixelBuffer:buffer withPresentationTime:lastTime];
        while (!writerInput.readyForMoreMediaData);
        CVBufferRelease(buffer);
        i++;
    }
    [writerInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
    }];
}


//+(void)writeImages:(NSArray *)array toPathFolder:(NSString*)path size:(CGSize)size
//{
//    for (int i = 0; i < array.count; i++) {
//        NSString *fullPath = [NSString stringWithFormat:@"%@%@_%i.jpg", path, [NSDate date].description, i];
//        CGImageRef ref = (__bridge CGImageRef)[array objectAtIndex:i];
//        [[[NSImage alloc]initWithCGImage:ref size:NSMakeSize(size.width, size.height)]saveAsJpegWithName:fullPath];
//    }
//}


@end
