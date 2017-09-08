//
//  IMCPixelTrainer.h
//  3DIMC
//
//  Created by Raul Catena on 3/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;
@class IMCPixelMap;
@class IMCPixelTraining;
@class IMCButtonLayer;
@class IMCRandomForests;

@interface IMCPixelTrainer : NSObject

@property (nonatomic, strong) IMCImageStack *stack;
@property (nonatomic, strong) NSArray<IMCPixelTraining *> * trainingNodes;
@property (nonatomic, strong) IMCPixelMap *mapPrediction;
@property (nonatomic, strong) NSString *theHash;
@property (nonatomic, strong) NSMutableArray *useChannels;
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, strong) NSMutableArray *options;
@property (nonatomic, assign) BOOL isSegmentation;

-(instancetype)initWithStack:(IMCImageStack *)stack andTrainings:(NSArray<IMCPixelTraining *>*)training;
-(NSInteger)numberRefsInScope;
-(NSMutableArray *)imageRefsInScopeForStack:(IMCImageStack *)stack;
-(void)toogleOption:(IMCButtonLayer *)lay;
-(NSImage *)imageForNode:(IMCButtonLayer *)node inStack:(IMCImageStack *)stack;

-(void)saveTrainingSettingsSegmentation:(IMCPixelTraining *)training;
-(void)saveTrainingMask:(IMCPixelTraining *)training;
-(void)prepTrainingNode:(IMCPixelTraining *)node;

-(BOOL)trainRandomForests;
-(void)loadDataInRRFF;
-(void)classifyPixels;
-(void)classifyPixelsAllSteps;

-(NSArray *)arrayTrainingOptions;
-(void)updateTrainingSettings;

@end
