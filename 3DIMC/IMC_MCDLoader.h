//
//  IMC_MCDLoader.h
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMC_DataLoader.h"
#import "IMCFileWrapper.h"

@interface IMC_MCDLoader : IMC_DataLoader

+(BOOL)loadMCD:(NSData *)data toIMCFileWrapper:(IMCFileWrapper *)wrapper;

@end
