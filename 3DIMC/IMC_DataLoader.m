//
//  IMC_Loader.m
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_DataLoader.h"

@implementation IMC_DataLoader

+(void)setChannelSettingsToMult1:(IMCImageStack *)imageStack{
    for (NSMutableDictionary *setts in imageStack.channelSettings) {
        [setts setValue:[NSNumber numberWithFloat:1.0f] forKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER];
    }
}

@end
