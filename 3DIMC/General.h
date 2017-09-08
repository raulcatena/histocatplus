//
//  General.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface General : NSObject

+(BOOL)isDirectory:(NSURL *)url;
+(NSInteger)runAlertModalAreYouSure;
+(NSInteger)runAlertModalAreYouSureWithMessage:(NSString *)message;
+(NSInteger)runAlertModalWithMessage:(NSString *)message;
+(void)drawIntAsString:(float)number WithFontName:(NSString *)fontName size:(float)size rect:(CGRect)rect;
+(void)checkAndCreateDirectory:(NSString *)path;

+(void)orderIndexesUponSelection:(NSMutableArray *)orderedArray indexes:(NSIndexSet *)indexSet;

+(void)addArrayOfStrings:(NSArray *)arrayStr toNSPopupButton:(NSPopUpButton *)button noneAtBeggining:(BOOL)none;
+(NSString*)jsonStringFromObject:(id)object prettryPrint:(BOOL)prettyPrint;
+(id)objectFromString:(NSString *)string;
+(NSIndexSet *)cellComputations;

@end
