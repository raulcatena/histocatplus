//
//  IMCMetricsCalculator.h
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;
@class IMCMetric;

@interface IMCMetricsCalculator : NSObject

+(NSArray *)resultsForMetric:(IMCMetric *)metric andComputation:(IMCComputationOnMask *)computation;
+(void)recalculateForMetric:(IMCMetric *)metric andComputation:(IMCComputationOnMask *)computation;

@end
