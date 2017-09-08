//
//  IMCTsneOperation.h
//  IMCReader
//
//  Created by Raul Catena on 9/16/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCMathOperation;
@protocol IMCCompOperation <NSObject>

-(void)finishedOperation:(IMCMathOperation *)operation;

@end

@interface IMCMathOperation : NSOperation{
    NSString * _nameGiven;
    int _iterationCursor;
}

@property (nonatomic, assign) float perplexity;

@property (nonatomic, assign) float *inputData;
@property (nonatomic, assign) int *inputDataInt;
@property (nonatomic, assign) double *inputDataDouble;

@property (nonatomic, assign) float *outputData;
@property (nonatomic, assign) int *outputDataInt;
@property (nonatomic, assign) double *outputDataDouble;

@property (nonatomic, assign) NSInteger numberOfValues;
@property (nonatomic, assign) NSInteger numberOfVariables;
@property (nonatomic, assign) NSInteger numberOfOutputVariables;

@property (nonatomic, assign) int iterationCursor;
@property (nonatomic, strong) NSString * nameGiven;
@property (nonatomic, assign) int numberOfCycles;

@property (nonatomic, assign) int cyclesLying;
@property (nonatomic, strong) NSIndexSet *indexSet;

@property (nonatomic, weak) id<IMCCompOperation>delegate;

@property (nonatomic, assign) BOOL opFinished;
@property (nonatomic, assign) BOOL opAdded;

@end

/*

http://alexsosn.github.io/ml/2015/11/05/iOS-ML.html
https://github.com/yconst/YCML
https://blog.bigml.com/2016/06/09/machine-learning-in-objective-c-has-never-been-easier/
https://ijoshsmith.com/2012/04/08/simple-genetic-algorithm-in-objective-c/

*/