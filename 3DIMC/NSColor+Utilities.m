//
//  NSColor+Utilities.m
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "NSColor+Utilities.h"

@implementation NSColor (Utilities)

+(NSArray *)collectColors:(NSInteger)numberOfColors withColoringType:(NSInteger)coloringType minumAmountColors:(NSInteger)minimum{
    NSMutableArray *colors = @[].mutableCopy;
    if(coloringType == 0)
        for(int i = 0; i< numberOfColors; i++)[colors addObject:[NSColor whiteColor]];
    else if(coloringType > 0 && coloringType < 3){
        float hueAngle = 1.0f/MAX(numberOfColors, minimum);
        
        for (int i = 0; i < numberOfColors; i++) {
            float hVal = 0.0f;
            if(coloringType == 1)hVal = 1.0f/3 * 2;
            if(coloringType == 2)hVal = 1.0f/6 * 5;
            hVal -= hueAngle * i;
            if(hVal < 0)hVal += 1.0f;
            [colors addObject:[NSColor colorWithHue:hVal saturation:1.0f brightness:1.0f alpha:1.0f]];
        }
    }else{
        return nil;//For heat coloring
    }
    return [NSArray arrayWithArray:colors];
}

+(NSColor *)colorInHueAtIndex:(NSInteger)index totalColors:(NSInteger)numberOfColors withColoringType:(NSInteger)coloringType minumAmountColors:(NSInteger)minimum{
    
    if(coloringType == 0)
        return [NSColor whiteColor];
    else if(coloringType > 0 && coloringType < 3){
        float hueAngle = 1.0f/MAX(numberOfColors, minimum);
        float hVal = 0.0f;
        if(coloringType == 1)hVal = 1.0f/3 * 2;
        if(coloringType == 2)hVal = 1.0f/6 * 5;
        hVal -= hueAngle * index;
        if(hVal < 0)hVal += 1.0f;
        return [NSColor colorWithHue:hVal saturation:1.0f brightness:1.0f alpha:1.0f];
    }
    return nil;
}

-(NSString *)hexEncoding{
    
    NSColor * color = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    NSString* hexString = [NSString stringWithFormat:@"%02X%02X%02X",
                           (int) (color.redComponent * 0xFF), (int) (color.greenComponent * 0xFF),
                           (int) (color.blueComponent * 0xFF)];
    return hexString;
}

+(NSColor *)colorFromHex:(NSString *)hexString withComponents:(int)components{
    unsigned vals[components];
    for (int i = 0; i < components; i++) {
        unsigned val;
        NSScanner *scanner = [NSScanner scannerWithString:[hexString substringWithRange:NSMakeRange(i * 2, 2)]];
        [scanner scanHexInt:&val];
        vals[i] = val;
    }
    NSColor *color = [NSColor colorWithRed:vals[0]/255.0f green:vals[1]/255.0f blue:vals[2]/255.0f alpha:components == 3?1.0f:vals[3]/255.0f];
    return color;
}

+(NSColor *)colorFromHexString:(NSString *)hexString{
    if(hexString.length != 6)return nil;
    return [NSColor colorFromHex:hexString withComponents:3];
}

+(NSColor *)colorWithAlphaFromHexString:(NSString *)hexString{
    if(hexString.length != 8)return nil;
    return [NSColor colorFromHex:hexString withComponents:4];
}


@end
