//
//  IMCMatlabLoader.h
//  3DIMC
//
//  Created by Raul Catena on 2/13/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_DataLoader.h"

@interface IMC_MatlabLoader : IMC_DataLoader
+(BOOL)loadMatDataETHZ:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack;
@end
