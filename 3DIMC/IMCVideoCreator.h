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

@interface IMCVideoCreator : NSObject
+(void)writeImagesAsMovie:(NSArray *)array toPath:(NSString*)path size:(CGSize)size duration:(int)duration;
//+(void)writeImages:(NSArray *)array toPathFolder:(NSString*)path size:(CGSize)size;
@end
