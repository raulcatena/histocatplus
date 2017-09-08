//
//  RandomForests.h
//  IMCReader
//
//  Created by Raul Catena on 11/4/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCMathOperation.h"

@interface IMCRandomForests : IMCMathOperation

@property (nonatomic, assign) int attributesPerSample;
@property (nonatomic, assign) int numberOfTrainingSamples;
@property (nonatomic, assign) int numberOfTestingSamples;
@property (nonatomic, assign) int numberOfClasses;
@property (nonatomic, assign) float *trainingData;
@property (nonatomic, assign) float *testingData;
@property (nonatomic, assign) float *outputProbabilities;

-(void)execute;

@end
