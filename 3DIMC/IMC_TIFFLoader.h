//
//  IMC_TIFFLoader.h
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMC_DataLoader.h"

@interface IMC_TIFFLoader : IMC_DataLoader
+(BOOL)loadNonTIFFData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack;
+(BOOL)loadTIFFData:(NSData *)data toIMCImageStack:(IMCImageStack *)imageStack;
@end
