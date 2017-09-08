//
//  IMCUtils.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMCUtils : NSObject
+(NSString *)randomStringOfLength:(int)length;

+(float)sumOfSquareDistancesPointArray:(NSArray *)array;//Array of NSValue points;
+(float)meanOfSquareDistancesPointArray:(NSArray *)array;
+(float)wardForArray1:(NSArray *)array1 array2:(NSArray *)array2;
+(float)minimalIncreaseOfVarianceForArray1:(NSArray *)array1 array2:(NSArray *)array2;
+ (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue;
+ (NSInteger)inputOptions:(NSArray *)values prompt:(NSString *)prompt;
+ (NSIndexSet *)inputTable:(NSArray *)values prompt:(NSString *)prompt;

@end
