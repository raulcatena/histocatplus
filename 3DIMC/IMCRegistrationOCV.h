//
//  IMCRegistrationOCV.h
//  3DIMC
//
//  Created by Raul Catena on 2/2/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#undef check
#import <Foundation/Foundation.h>


@interface IMCRegistrationOCV : NSObject

+(void)alignTwoImages:(NSImage *)imageA imageB:(NSImage *)imageB;

@end
