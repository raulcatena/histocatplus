//
//  IMCMaskTraining.m
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMaskTraining.h"
#import "IMCCellTrainerTool.h"
#import "IMCCell3DTrainerTool.h"
#import "IMCComputationOnMask.h"
#import "IMC3DMask.h"
#import "IMCPixelClassification.h"

@interface IMCMaskTraining(){
    
}
@end

@implementation IMCMaskTraining


-(IMCComputationOnMask *)computation{
    return (IMCComputationOnMask *)self.parent;
}

-(void)setParent:(IMCNodeWrapper *)parent{
    if(parent){
        if(!parent.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS])
            parent.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS] = @[].mutableCopy;
        if(![parent.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS] containsObject:self.jsonDictionary])
            [parent.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS] addObject:self.jsonDictionary];
    }
    [super setParent:parent];
}

-(NSString *)itemSubName{
    return @"Cell Training";
}
-(void)loadBufferAction{
    self.training = (int *)calloc([self segments], sizeof(int));

    for (NSString *key in [self labels]) {
        NSArray *arr = self.trainingDictionary[key];
        for (NSNumber *num in arr) {
            self.training[num.integerValue - 1] = key.intValue;
        }
    }
    self.isLoaded = YES;
}
-(void)loadBuffer{
    if(!self.computation.isLoaded){
        [self.computation loadLayerDataWithBlock:^{
            [self loadBufferAction];
        }];
    }else
        [self loadBufferAction];
}
-(void)loadLayerDataWithBlock:(void (^)())block{
    if(![self canLoad])return;
    [self loadBuffer];
    NSWindowController *cont;
    if([self.parent isMemberOfClass:[IMCComputationOnMask class]])
        cont = [[IMCCellTrainerTool alloc]initWithComputation:self.computation andTraining:self];
    if([self.parent isMemberOfClass:[IMC3DMask class]])
        cont = [[IMCCell3DTrainerTool alloc]initWithComputation:self.computation andTraining:self];
    [[cont window] makeKeyAndOrderFront:cont];
    [super loadLayerDataWithBlock:block];
    
}
-(NSMutableDictionary *)trainingDictionary{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_TRAINED])
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_TRAINED] = @{}.mutableCopy;
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_TRAINED];
}
-(NSMutableArray *)labels{
    return self.trainingDictionary.allKeys.mutableCopy;
}
-(NSMutableArray *)labelsTitles{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_LABELS])
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_LABELS] = @[].mutableCopy;
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_LABELS];
}
-(NSMutableArray *)useChannels{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_USE_CHANNELS])
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_USE_CHANNELS] = @[].mutableCopy;
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_USE_CHANNELS];
}
-(NSMutableArray *)labelArray:(NSInteger)label{
    NSString *key = [NSString stringWithFormat:@"%li", label];
    if(!self.trainingDictionary[key])
        self.trainingDictionary[key] = @[].mutableCopy;
    return self.trainingDictionary[key];
}

-(NSInteger)segments{
    if([self.parent isMemberOfClass:[IMCComputationOnMask class]])
        return self.computation.mask.numberOfSegments;
    if([self.parent isMemberOfClass:[IMC3DMask class]])
        return [(IMC3DMask *)self.computation segmentedUnits];
    return 0;
}

-(void)regenerateDictTraining{
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_TRAINED] = nil;
    NSInteger segments = [self segments];
    for (NSInteger i = 0; i < segments; i++) {
        if(self.training[i] > 0){
            NSMutableArray *arr = [self labelArray:self.training[i]];
            [arr addObject:[NSNumber numberWithInteger:i + 1]];//The CellId
        }
    }
}

@end
