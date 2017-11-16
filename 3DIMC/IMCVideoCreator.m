//
//  IMCVideoCreator.m
//  IMCReader
//
//  Created by Raul Catena on 2/5/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCVideoCreator.h"

@interface IMCVideoCreator(){
    NSInteger images;
    int duration;
    CGSize size;
    CVPixelBufferRef buffer;
}

@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, strong) AVAssetWriterInput* writerInput;

@end

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
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}
+ (CVPixelBufferRef)pixelBufferWithData:(UInt8 *)data width:(NSInteger)width height:(NSInteger)height
{

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
                        kCFAllocatorDefault, width, height,
                        kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CFDataRef rgbData = CFDataCreate(NULL, data, width * height * 4);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImg =  CGImageCreate (
                                       width,
                                       height,
                                       8,
                                       32,
                                       width * 4,
                                       rgbColorSpace,
                                       (CGBitmapInfo)kCGImageAlphaLast, // ?        CGBitmapInfo bitmapInfo,
                                       provider,   //? CGDataProviderRef provider,
                                       NULL, //const CGFloat decode[],
                                       true, //bool shouldInterpolate,
                                       kCGRenderingIntentDefault // CGColorRenderingIntent intent
                                       );
    CGContextRef context = CGBitmapContextCreate(
                                                 pxdata, width, height,
                                                 8, CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGBitmapByteOrder32Big |
                                                 kCGImageAlphaNoneSkipLast);//It was kCGBitmapByteOrder32Little but the buffer from the CGImageRef had inverted byte order
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(cgImg),
                                           CGImageGetHeight(cgImg)), cgImg);
    
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImg);
    CFRelease(rgbColorSpace);
    CGDataProviderRelease(provider);
    CFRelease(rgbData);
    
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

+(void)writeImagesAsMovieWithBuffers:(UInt8 **)data images:(NSInteger)images toPath:(NSString*)path size:(CGSize)size duration:(int)duration
{
    
    if(images == 0)
        return;
    
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
    
    buffer = [IMCVideoCreator pixelBufferWithData:data[0] width:(NSInteger)size.width height:(NSInteger)size.height];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    CVBufferRelease(buffer);
    
    for (int i = 1; i < images; i++) {
        CMTime lastTime=CMTimeMake(i, duration);
        
        buffer = [IMCVideoCreator pixelBufferWithData:data[i] width:(NSInteger)size.width height:(NSInteger)size.height];
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

-(instancetype)initWithSize:(CGSize)sizePassed duration:(int)durationFrame path:(NSString *)path{
    if(self = [self init]){
        duration = durationFrame;
        size = sizePassed;
        
        NSError *error = nil;
        _videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                               fileType:AVFileTypeQuickTimeMovie
                                                                  error:&error];
        NSParameterAssert(_videoWriter);
        
        NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       AVVideoCodecAppleProRes422, AVVideoCodecKey,//AVVideoCodecJPEG Low //AVVideoCodecAppleProRes4444 High
                                       [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                       [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                       nil];
        
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                             outputSettings:videoSettings];
        
        _writerInput.expectsMediaDataInRealTime = YES;
        
        NSDictionary* bufferAttributes=[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey,nil];
        
        _adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_writerInput sourcePixelBufferAttributes:bufferAttributes];
        
        NSParameterAssert(_writerInput);
        NSParameterAssert([_videoWriter canAddInput:_writerInput]);
        [_videoWriter addInput:_writerInput];
        
        //Start a session:
        [_videoWriter startWriting];
        [_videoWriter startSessionAtSourceTime:kCMTimeZero];
        
        images = 0;
    }
    return self;
}

-(void)addBuffer:(UInt8 *)bufferFrame{
    
    if(images == 0)
        buffer = NULL;
    
    buffer = [IMCVideoCreator pixelBufferWithData:bufferFrame width:(NSInteger)size.width height:(NSInteger)size.height];
    if(images == 0)
        CVPixelBufferPoolCreatePixelBuffer (NULL, _adaptor.pixelBufferPool, &buffer);
    [_adaptor appendPixelBuffer:buffer withPresentationTime:images == 0 ? kCMTimeZero : CMTimeMake(images, duration)];
    while (!_writerInput.readyForMoreMediaData);
    CVBufferRelease(buffer);
    
    images++;
}

-(void)finishVideo{
    [_writerInput markAsFinished];
    [_videoWriter finishWritingWithCompletionHandler:^{
        CVPixelBufferPoolRelease(_adaptor.pixelBufferPool);
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
