//
//  IMCKMeansOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCKMeansOperation.h"
#import "kmeans.h"

@implementation IMCKMeansOperation

-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"kMeans" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
    }
    return _nameGiven;
}

-(NSString *)description{
    if(self.opFinished == YES)return self.nameGiven;
    return [NSString stringWithFormat:@"%i/%i-%@", self.iterationCursor, self.numberOfCycles, self.nameGiven];
}

-(NSInteger)numberOfOutputVariables{
    return 1;
}

-(void)main{
    @autoreleasepool {
        kmeans(self.inputData,
               (int)self.numberOfValues,//Number of cells
               (int)self.numberOfVariables,//Variables
               self.numberOfClusters,//Clusters
               self.numberOfRestarts,//Number of restarts
               self.outputDataInt,
               &_iterationCursor);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
