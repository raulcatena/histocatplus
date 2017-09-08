//
//  IMCTsneOperation.m
//  IMCReader
//
//  Created by Raul Catena on 9/16/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCMathOperation.h"
#import "tsne_c.h"

@implementation IMCMathOperation

-(NSString *)nameGiven{
    
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
                     &_iterationCursor, self.numberOfCycles, self.cyclesLying);
        
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

-(void)dealloc{
    
    if(self.outputData)free(self.outputData);
    if(self.outputDataInt)free(self.outputDataInt);
    if(self.outputDataDouble)free(self.outputDataDouble);
    NSLog(@"Math dealloc");
    if(self.inputData)free(self.inputData);
    if(self.inputDataInt)free(self.inputDataInt);
    if(self.inputDataDouble)free(self.inputDataDouble);
}

@end
