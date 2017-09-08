//
//  NSColor+Utilities.h
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Utilities)

+(NSArray *)collectColors:(NSInteger)numberOfColors withColoringType:(NSInteger)coloringType minumAmountColors:(NSInteger)minimum;
+(NSColor *)colorInHueAtIndex:(NSInteger)index totalColors:(NSInteger)numberOfColors withColoringType:(NSInteger)coloringType minumAmountColors:(NSInteger)minimum;

//Hex management
-(NSString *)hexEncoding;
+(NSColor *)colorFromHexString:(NSString *)hexString;
+(NSColor *)colorWithAlphaFromHexString:(NSString *)hexString;

@end
