//
//  IMC_TxtLoader.h
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMC_DataLoader.h"
#import "IMCImageStack.h"


@interface IMC_TxtLoader : IMC_DataLoader

+(BOOL)loadTXTData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack;
@end
