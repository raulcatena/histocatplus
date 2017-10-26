//
//  IMCKMeansOperation.h
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCTsneOperation.h"

@interface IMCKMeansOperation : IMCTsneOperation
@property (nonatomic, assign) int numberOfRestarts;
@property (nonatomic, assign) int numberOfClusters;
@end
