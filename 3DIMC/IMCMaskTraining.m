//
//  IMCMaskTraining.m
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMaskTraining.h"
#import "IMCCellTrainerTool.h"
#import "IMCComputationOnMask.h"
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
    self.training = (int *)calloc(self.computation.mask.numberOfSegments, sizeof(int));
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
        NSLog(@"Load comp first");
        [self.computation loadLayerDataWithBlock:^{
            NSLog(@"Done with comp");
            [self loadBufferAction];
        }];
    }else
        [self loadBufferAction];
}
-(void)loadLayerDataWithBlock:(void (^)())block{
    [self loadBuffer];
    IMCCellTrainerTool *tool = [[IMCCellTrainerTool alloc]initWithComputation:self.computation andTraining:self];
    [[tool window] makeKeyAndOrderFront:tool];
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

-(void)regenerateDictTraining{
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_TRAINING_TRAINED] = nil;
    for (NSInteger i = 0; i < self.computation.mask.numberOfSegments; i++) {
        if(self.training[i] > 0){
            NSMutableArray *arr = [self labelArray:self.training[i]];
            [arr addObject:[NSNumber numberWithInteger:i + 1]];//The CellId
        }
    }
}

@end
