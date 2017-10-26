//
//  IMCFlockOperation.m
//  3DIMC
//
//  Created by Raul Catena on 10/26/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCFlockOperation.h"
#import "flock.h"

@implementation IMCFlockOperation

-(NSString *)nameGiven{
    if(!_nameGiven){
        _nameGiven = [@"Flock_" stringByAppendingString:[NSString stringWithFormat:@"%@", [NSDate date]]];
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
        directMethod(self.numberOfVariables, self.numberOfValues, self.flockInput, self.outputDataInt);
        self.opFinished = YES;
        [self.delegate finishedOperation:self];
    }
}

@end
