//
//  IMCVideoCreator.h
//  IMCReader
//
//  Created by Raul Catena on 2/5/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    IMCVIDEO_TYPE_MPG4,
    IMCVIDEO_TYPE_QUICKTIME
} IMCVideoType;

@interface IMCVideoCreator : NSObject
+(void)writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration;
+(void)writeImagesAsMovieWithBuffers:(UInt8 **)data  images:(NSInteger)images toPath:(NSString*)path size:(CGSize)size duration:(int)duration;
//+(void)writeImages:(NSArray *)array toPathFolder:(NSString*)path size:(CGSize)size;

-(instancetype)initWithSize:(CGSize)sizePassed duration:(int)durationFrame path:(NSString *)path videoType:(IMCVideoType)videoType;
-(void)addBuffer:(UInt8 *)bufferFrame;
-(void)finishVideo;

@end
