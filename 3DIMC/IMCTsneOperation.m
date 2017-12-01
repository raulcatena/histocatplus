//
//  IMCTsneOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/16/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCTsneOperation.h"
#import "tsne_c.h"

@implementation IMCTsneOperation

-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"tSNE" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
    }
    return _nameGiven;
}

-(NSString *)description{
    if(self.opFinished == YES)return self.nameGiven;
    return [NSString stringWithFormat:@"%i/%i-%@", self.iterationCursor, self.numberOfCycles, self.nameGiven];
}

-(void)main{
    @autoreleasepool {
        perform_tsne(self.inputData,
                     (int)self.numberOfVariables,
                     (unsigned int)self.numberOfValues,
                     self.outputData,
                     (int)self.numberOfOutputVariables,
                     self.perplexity,
                     &_iterationCursor, self.numberOfCycles, self.cyclesLying,
                     &_stopCursor);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
