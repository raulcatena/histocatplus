//
//  IMCMetricsCalculator.m
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMetricsCalculator.h"
#import "IMCMetric.h"

@implementation IMCMetricsCalculator

+(NSArray *)resultsForMetric:(IMCMetric *)metric andComputation:(IMCComputationOnMask *)computation{
    if(metric && metric.metricType && metric.primaryChannels.count > 0){
        
    }
    return nil;
}
+(void)recalculateForMetric:(IMCMetric *)metric andComputation:(IMCComputationOnMask *)computation{

}

@end
