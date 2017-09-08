//
//  IMCCellTrainer.m
//  3DIMC
//
//  Created by Raul Catena on 3/10/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellTrainer.h"
#import "IMCMaskTraining.h"
#import "IMCComputationOnMask.h"
#import "IMCPixelClassification.h"
#import "IMCRandomForests.h"


@interface IMCCellTrainer()
@property (nonatomic, strong) IMCRandomForests * randomForests;
@end

@implementation IMCCellTrainer

-(instancetype)initWithComputation:(IMCComputationOnMask *)computation andTrainings:(NSArray<IMCMaskTraining *>*)trainings{
    self = [self init];
    if(self){
        self.trainingNodes = trainings;
        self.computation = computation;
        self.labels = self.trainingNodes.firstObject.labelsTitles;
        self.useChannels = self.trainingNodes.firstObject.useChannels;
    }
    return self;
}


-(void)toogleChannel:(NSInteger)channel{
    NSMutableArray *use = self.trainingNodes.firstObject.useChannels;
    if([use containsObject:[NSNumber numberWithInteger:channel]])
        [use removeObject:[NSNumber numberWithInteger:channel]];
    else
        [use addObject:[NSNumber numberWithInteger:channel]];
}


-(BOOL)trainRandomForests{
    //Pre. Calculate number of pixels trained
    NSInteger counter = 0;
    NSInteger chanCount = 0;
    NSInteger labelsCount = 0;
    NSMutableArray *scopeImages = @[].mutableCopy;
    
    for (IMCMaskTraining *train in self.trainingNodes) {
        if(!train.computation.isLoaded)
            [train.computation loadLayerDataWithBlock:nil];
        while (!train.computation.isLoaded);
        NSArray *refs = [train useChannels];
        if(chanCount == 0)chanCount = refs.count;
        if(chanCount != refs.count){
            [General runAlertModalWithMessage:@"Can't continue. Trainings have different amount of features"];
            return NO;
        }
        if(labelsCount == 0)labelsCount = train.labelsTitles.count;
        if(labelsCount != self.labels.count){
            [General runAlertModalWithMessage:@"Can't continue. Trainings have different amount of labels"];
            return NO;
        }
        [scopeImages addObjectsFromArray:refs];
        
        NSInteger subPix = train.computation.mask.numberOfSegments;
        for(int j = 0; j < subPix; j++)
            if(train.training[j] > 0)
                counter++;
    }
    
    if(chanCount == 0 || labelsCount == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [General runAlertModalWithMessage:@"Can't continue. No features or labels defined"];
        });
        return NO;
    }
    
    //First. Allocate arrays to pass to the random forests algorithm
    float * filteredChannelsAndClassTraining = (float *)calloc((chanCount + 1) * counter, sizeof(float));
    
    //Prepare training buffer
    counter = 0;
    NSArray *useChannels = self.trainingNodes.firstObject.useChannels;
    
    //Get max (to remap values)
    NSMutableArray *maxima = @[].mutableCopy;
    for (NSNumber *num in useChannels)
        [maxima addObject:@([self.trainingNodes.firstObject.computation maxForIndex:num.integerValue])];
    
    for (IMCMaskTraining *train in self.trainingNodes) {
        NSInteger cells = train.computation.mask.numberOfSegments;
        for(NSInteger i = 0; i < cells; i++){
            if(train.training[i] > 0){//It's a training cell;
                for (int j = 0; j < chanCount; j++){//Add value{
                    //printf(" %f", train.computation.computedData[[useChannels[j]integerValue]][i]);
                    float max = [maxima[j]floatValue];
                    if(max != .0f)
                        filteredChannelsAndClassTraining[counter * (chanCount + 1) + j] = (float)train.computation.computedData[[useChannels[j]integerValue]][i]/max;
                }
                
                //If is training I need to specify the class
                filteredChannelsAndClassTraining[counter * (chanCount + 1) + chanCount] = (float)train.training[i];
                counter++;
            }
        }
    }
    
    self.randomForests = [[IMCRandomForests alloc]init];
    self.randomForests.trainingData = filteredChannelsAndClassTraining;
    self.randomForests.numberOfTrainingSamples = (int)counter;
    self.randomForests.numberOfClasses = (int)labelsCount;
    self.randomForests.attributesPerSample = (int)chanCount;
    
    for (int i =0; i < scopeImages.count; i++) {
        CGImageRef ref = (__bridge CGImageRef)[scopeImages objectAtIndex:i];
        CFRelease(ref);
    }
    return YES;
}
-(void)loadDataInRRFF{
    //Prepare test buffer
    NSInteger segments = self.computation.mask.numberOfSegments;
    NSArray *channels = [self.trainingNodes.firstObject useChannels];
    NSInteger chanCount = channels.count;
    
    BOOL wasLoaded = self.computation.isLoaded;
    if(!self.computation.isLoaded)
        [self.computation loadLayerDataWithBlock:nil];
    while (!self.computation.isLoaded);
    
    float * allDataProbando[channels.count];
    for (int i = 0; i < chanCount; i++) {
        float * data = self.computation.computedData[[channels[i]integerValue]];
        allDataProbando[i] = data;
    }
    
    //Get max (to remap values)
    NSMutableArray *maxima = @[].mutableCopy;
    for (NSNumber *num in channels)
        [maxima addObject:@([self.trainingNodes.firstObject.computation maxForIndex:num.integerValue])];
    float * filteredChannelsAndClassProbando = (float *)calloc((chanCount + 1) * segments, sizeof(float));
    for(NSInteger i = 0; i < segments; i++){
        for (int j = 0; j < chanCount; j++){
            float max = [maxima[j]floatValue];
            if(max != .0f)
                filteredChannelsAndClassProbando[i * (chanCount + 1) + j] = (float)allDataProbando[j][i]/max;
        }
    }
    if(self.randomForests.testingData)
        free(self.randomForests.testingData);
    self.randomForests.testingData = filteredChannelsAndClassProbando;
    self.randomForests.numberOfTestingSamples = (int)segments;
    if(self.randomForests.outputProbabilities)
        free(self.randomForests.outputProbabilities);
    self.randomForests.outputProbabilities = (float *)calloc(segments * self.labels.count, sizeof(float));
    if(!wasLoaded)[self.computation unLoadLayerDataWithBlock:nil];
}
-(void)classifyCells{
    [self.randomForests execute];
}
-(float *)randomFResults{
    return self.randomForests.testingData;
}
-(void)addResultsToComputation{
    if(!self.computation.isLoaded)
       [self.computation loadLayerDataWithBlock:nil];
    while (!self.computation.isLoaded);
    
    NSMutableArray *channels = self.computation.channels;
    
    NSInteger oldNumberOfChannels = channels.count;
    NSInteger trainedLabels = self.trainingNodes.firstObject.labels.count;
    NSInteger labelsToAdd = self.trainingNodes.firstObject.labels.count + 2;//2 is because I add one column per category as binary, plus another column with all categories, and a final one with the certainty
    NSInteger cells = self.computation.mask.numberOfSegments;
    
    float ** new = calloc(labelsToAdd, sizeof(float *));
    float ** old = calloc(oldNumberOfChannels, sizeof(float *));
    for (NSInteger i = 0; i < labelsToAdd; i++)
        new[i] = calloc(cells, sizeof(float));
    
    for (NSInteger i = 0; i < cells; i++) {
        float val = self.randomFResults[i * (self.useChannels.count + 1) + self.useChannels.count];
        float theClass = floorf(val);
        float prob = val - theClass;
        
        for (NSInteger j = 1; j < trainedLabels + 1; j++) {
            if((NSInteger)theClass == j)
                new[j - 1 + 2][i] = 1;
            else new[j - 1 + 2][i] = 0;
        }
        new[0][i] = theClass;
        new[1][i] = prob;
    }


    NSUInteger alreadyInComp = [channels indexOfObjectIdenticalTo:self.trainingNodes.firstObject.itemName];
    if(alreadyInComp != NSNotFound){
        
        for (NSInteger i = alreadyInComp; i < alreadyInComp + labelsToAdd; i++){
            if(self.computation.computedData[i])
                free(self.computation.computedData[i]);
            self.computation.computedData[i] = new[i - alreadyInComp];
        }
    }
    
    else{
        
        [channels addObject:self.trainingNodes.firstObject.itemName?self.trainingNodes.firstObject.itemName:@"NA"];
        [channels addObject:[self.trainingNodes.firstObject.itemName stringByAppendingString:@"_certainty"]];
        for (NSString *str in self.trainingNodes.firstObject.labelsTitles)
            [channels addObject:str.copy];
        
        if(self.computation.computedData){
            for(NSInteger i = 0; i < oldNumberOfChannels; i++)
                old[i] = self.computation.computedData[i];
            free(self.computation.computedData);
        }
        
        self.computation.computedData = calloc(channels.count, sizeof(float *));
        
        for (NSInteger i = 0; i < oldNumberOfChannels; i++)
            self.computation.computedData[i] = old[i];
        for (NSInteger i = oldNumberOfChannels; i < channels.count; i++)
            self.computation.computedData[i] = new[i - oldNumberOfChannels];
    }
    [self.computation saveData];
    free(new);
    free(old);
}

-(void)classifyCellsAllSteps{
    if([self trainRandomForests]){
        [self loadDataInRRFF];
        [self classifyCells];
    }
}


@end
