//
//  IMCBlendModes.h
//  IMCReader
//
//  Created by Raul Catena on 9/27/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMCBlendModes : NSObject

+(NSString *)nameOfBlendMode:(int)mode;
+(NSArray *)blendModes;
+(CGBlendMode)blendModeForValue:(NSInteger)mode;

@end
