//
//  IMCWaterShedSegmenter.h
//  3DIMC
//
//  Created by Raul Catena on 10/23/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;

@interface IMCWaterShedSegmenter : NSObject


+(void)wizard2DWatershedIndexes:(NSArray *)inOrderIndexes scopeImage:(IMCImageStack *)inScopeImage scopeImages:(NSArray<IMCImageStack *>*)inScopeImages;
+(void)extractMaskFromRender:(IMCImageStack *)stack channels:(NSArray *)inOrderIndexes dictChannel:(NSDictionary *)dictChannel framingChannel:(NSInteger)schannel dictSChannel:(NSDictionary *)dictSChannel threshold:(float)threshold gradient:(float)gradient minKernel:(int)minKernel expansion:(int)expansion name:(NSString *)name;

@end
