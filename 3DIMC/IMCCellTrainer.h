//
//  IMCCellTrainer.h
//  3DIMC
//
//  Created by Raul Catena on 3/10/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>


@class IMCComputationOnMask;
@class IMCMaskTraining;
@class IMCRandomForests;

@interface IMCCellTrainer : NSObject

@property (nonatomic, strong) IMCComputationOnMask *computation;
@property (nonatomic, strong) NSArray<IMCMaskTraining *> * trainingNodes;
@property (nonatomic, strong) NSString *theHash;
@property (nonatomic, strong) NSMutableArray *useChannels;
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSMutableArray *options;
@property (nonatomic, assign) BOOL isSegmentation;
@property (nonatomic, readonly) float * randomFResults;

-(instancetype)initWithComputation:(IMCComputationOnMask *)stack andTrainings:(NSArray<IMCMaskTraining *>*)training;
-(void)toogleChannel:(NSInteger)channel;

-(NSInteger)numberOfSegments;


//-(CGImageRef)pMap;
//-(void)saveTraining;
//-(void)prepTrainingNode:(IMCMaskTraining *)node;

-(BOOL)trainRandomForests;
-(void)loadDataInRRFF;
-(void)classifyCells;
-(void)classifyCellsAllSteps;
-(void)addResultsToComputation;

@end
