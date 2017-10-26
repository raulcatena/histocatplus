//
//  IMCBhSNEOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/29/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCBhSNEOperation.h"
#import "bhsne.h"


@implementation IMCBhSNEOperation

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
    float *trans = (float *)calloc(self.numberOfValues * 2, sizeof(float));
    for(NSInteger i = 0; i < self.numberOfValues * 2; i++)trans[i] = (float)self.outputDataDouble[i];
    return trans;
}

-(void)main{
    @autoreleasepool {

        BHSNE bh;
        bh.run(self.inputDataDouble, (unsigned int)self.numberOfValues, (int)self.numberOfVariables, self.outputDataDouble, (int)self.numberOfOutputVariables, self.perplexity, self.thetha, &_iterationCursor, self.numberOfCycles, self.cyclesLying);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
