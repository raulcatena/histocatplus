//
//  IMC_Loader.h
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMCFileWrapper.h"
#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"

@protocol Loader <NSObject>

-(NSURL *)fileURL;

@end

@interface IMC_DataLoader : NSObject

@property (nonatomic, assign) id<Loader>delegate;
+(void)setChannelSettingsToMult1:(IMCImageStack *)imageStack;

@end
