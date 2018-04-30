//
//  IMCCellDataExport.h
//  3DIMC
//
//  Created by Raul Catena on 2/24/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;

@interface IMCCellDataExport : NSObject

//+(BOOL)saveDocumentAtPath:(NSString *)path computations:(NSArray <IMCComputationOnMask *> *)computations;
+(BOOL)exportComputations:(NSArray<IMCComputationOnMask *> *)computations atPath:(NSString *)path channels:(NSIndexSet *)channels;

@end
