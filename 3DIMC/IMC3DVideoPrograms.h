//
//  IMC3DVideoPrograms.h
//  3DIMC
//
//  Created by Raul Catena on 11/16/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCMtkView;

@interface IMC3DVideoPrograms : NSObject

+(void)recordYVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView active:(BOOL *)activeFlag;
+(void)recordStackVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView slices:(NSInteger)slices active:(BOOL *)activeFlag;
+(void)recordSliceVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView slices:(NSInteger)slices active:(BOOL *)activeFlag;
+(void)recordRockVideoWithPath:(NSString *)fullPath size:(CGSize)sizeFrame framDuration:(int)frameDuration metalView:(IMCMtkView *)metalView active:(BOOL *)activeFlag;

@end
