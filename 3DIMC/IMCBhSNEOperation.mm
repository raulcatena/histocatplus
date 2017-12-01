//
//  IMCBhSNEOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/29/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCBhSNEOperation.h"
#import "bhsne.h"

@interface IMCBhSNEOperation(){
    float *stagingBuffer;
}

@end

@implementation IMCBhSNEOperation

@synthesize outputData = _outputData;

-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"bhSNE" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
    }
    return _nameGiven;
}

-(NSString *)description{
    if(self.opFinished == YES)return self.nameGiven;
    return [NSString stringWithFormat:@"%i/%i-%@", self.iterationCursor, self.numberOfCycles, self.nameGiven];
}

-(float *)outputData{
    if(!_outputData)
        _outputData = (float *)calloc(self.numberOfValues * self.numberOfOutputVariables, sizeof(float));
    NSInteger values = self.numberOfValues * self.numberOfOutputVariables;
    for(NSInteger i = 0; i < values; i++)_outputData[i] = (float)self.outputDataDouble[i];
    return _outputData;
}

-(void)main{
    @autoreleasepool {
        stagingBuffer = NULL;
        BHSNE bh;
        bh.run(self.inputDataDouble, (unsigned int)self.numberOfValues, (int)self.numberOfVariables, self.outputDataDouble, (int)self.numberOfOutputVariables, self.perplexity, self.thetha, &_iterationCursor, self.numberOfCycles, self.cyclesLying, &_stopCursor);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
