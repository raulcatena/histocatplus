//
//  RandomForests.m
//  IMCReader
//
//  Created by Raul Catena on 11/4/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCRandomForests.h"
#import "RandomForests.hpp"

@implementation IMCRandomForests

-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"randomForests" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
    }
    return _nameGiven;
}

-(NSString *)description{
    if(self.opFinished == YES)return self.nameGiven;
    return [NSString stringWithFormat:@"%i/%i-%@", self.iterationCursor, self.numberOfCycles, self.nameGiven];
}

-(void)execute{
    randomForest(self.attributesPerSample, self.numberOfTrainingSamples, self.numberOfTestingSamples, self.numberOfClasses, self.trainingData, self.testingData, self.outputProbabilities);
}

-(void)main{
    @autoreleasepool {
        randomForest(self.attributesPerSample, self.numberOfTrainingSamples, self.numberOfTestingSamples, self.numberOfClasses, self.trainingData, self.testingData, self.outputProbabilities);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

-(void)dealloc{
    if(self.outputProbabilities)free(self.outputProbabilities);
    NSLog(@"RRFF dealloc");
    if(self.testingData)free(self.testingData);
    if(self.trainingData)free(self.trainingData);
}

@end
