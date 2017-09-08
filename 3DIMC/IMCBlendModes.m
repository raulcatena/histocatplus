//
//  IMCBlendModes.m
//  IMCReader
//
//  Created by Raul Catena on 9/27/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "IMCBlendModes.h"

@implementation IMCBlendModes

+(NSString *)nameOfBlendMode:(int)mode{
    NSLog(@"mode is %i", mode);
    return [[IMCBlendModes blendModes]objectAtIndex:mode];
}

+(CGBlendMode)blendModeForValue:(NSInteger)mode{
    switch (mode) {
        case 0: return kCGBlendModeNormal;
        case 1: return kCGBlendModeMultiply;
        case 2: return kCGBlendModeScreen;
        case 3: return kCGBlendModeOverlay;
        case 4: return kCGBlendModeDarken;
        case 5: return kCGBlendModeLighten;
        case 6: return kCGBlendModeColorDodge;
        case 7: return kCGBlendModeColorBurn;
        case 8: return kCGBlendModeSoftLight;
        case 9: return kCGBlendModeHardLight;
        case 10: return kCGBlendModeDifference;
        case 11: return kCGBlendModeExclusion;
        case 12: return kCGBlendModeHue;
        case 13: return kCGBlendModeSaturation;
        case 14: return kCGBlendModeColor;
        case 15: return kCGBlendModeLuminosity;
        case 16: return kCGBlendModeClear;
        case 17: return kCGBlendModeCopy;
        case 18: return kCGBlendModeSourceIn;
        case 19: return kCGBlendModeSourceOut;
        case 20: return kCGBlendModeSourceAtop;
        case 21: return kCGBlendModeDestinationOver;
        case 22: return kCGBlendModeDestinationIn;
        case 23: return kCGBlendModeDestinationOut;
        case 24: return kCGBlendModeDestinationAtop;
        case 25: return kCGBlendModeXOR;
        case 26: return kCGBlendModePlusDarker;
        case 27: return kCGBlendModePlusLighter;
    }
    return kCGBlendModeScreen;
}

+(NSArray *)blendModes{
    return @[@"Normal",
             @"Multiply",
             @"Screen",
             @"Overlay",
             @"Darken",
             @"Lighten",
             @"ColorDodge",
             @"ColorBurn",
             @"SoftLight",
             @"HardLight",
             @"Difference",
             @"Exclusion",
             @"Hue",
             @"Saturation",
             @"Color",
             @"Luminosity",
             @"Clear",
             @"Copy",
             @"SourceIn",
             @"SourceOut",
             @"SourceAtop",
             @"DestinationOver",
             @"DestinationIn",
             @"DestinationOut",
             @"DestinationAtop",
             @"XOR",
             @"PlusDarker",
             @"PlusLighter"];
}

@end
