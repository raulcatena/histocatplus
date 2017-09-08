//
//  IMCMaskTraining.h
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"

@class IMCComputationOnMask;
@interface IMCMaskTraining : IMCNodeWrapper

@property (nonatomic, weak) IMCComputationOnMask *computation;
@property (nonatomic, readonly) NSMutableArray *labelsTitles;
@property (nonatomic, readonly) NSMutableArray *useChannels;
@property (nonatomic, assign) int * training;

-(NSMutableDictionary *)trainingDictionary;
-(NSMutableArray *)labels;

-(void)loadBuffer;
-(void)regenerateDictTraining;

@end
