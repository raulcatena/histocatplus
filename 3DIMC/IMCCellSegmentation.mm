//
//  IMCCellSegmentation.m
//  3DIMC
//
//  Created by Raul Catena on 2/14/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellSegmentation.h"
#import "NSString+MD5.h"
#import "IMCPixelTraining.h"
#import "IMCPixelMap.h"
#import "IMCMasks.h"

@interface IMCCellSegmentation ()
@property (nonatomic, assign) int *maskGenerated;
@end

@implementation IMCCellSegmentation

-(instancetype)initWithStack:(IMCImageStack *)stack andTraining:(IMCPixelTraining *)training{
    self = [self initWithWindowNibName:NSStringFromClass([IMCCellSegmentation class])];
    if(self){
        if(!training){
            training = [[IMCPixelTraining alloc]init];
            training.itemName = [@"SegTraining_" stringByAppendingString:stack.itemName];
            training.parent = stack;//Important to set this before loading buffer
            [training loadBuffer];
        }
        self.trainer = [[IMCPixelTrainer alloc]initWithStack:stack andTrainings:@[training]];
        self.trainer.labels = @[@"Nucleus", @"Cytoplasm", @"Membrane", @"Background"].mutableCopy;
        self.trainer.isSegmentation = YES;
    }
    
    return self;
}

-(void)saveColorizedPMap{
    [self.trainer.mapPrediction saveColorizedPixelMapPredictions];
}
-(void)saveTraining:(NSButton *)sender{
    [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
    [self.trainer saveTrainingMask:self.trainer.trainingNodes.firstObject];
}
-(void)savePredictionMap:(NSButton *)sender{
    [self.trainer.mapPrediction savePixelMapPredictions];
    [self saveColorizedPMap];
}
-(void)imageAsIlastik:(NSButton *)sender{
    [self saveColorizedPMap];
}

-(IBAction)runProfilerPipelineWithImage:(NSButton *)sender{
    [self saveColorizedPMap];
    
    [IMCCellSegmenter saveCellProfilerPipelineWithImageWithWf:self.trainer.stack.workingFolder
                                                              hash:self.trainer.mapPrediction.itemHash.copy
                                                       minCellDiam:self.minCellDiam.stringValue
                                                       maxCellDiam:self.maxCellDiam.stringValue
                                                      lowThreshold:self.lowerThreshold.stringValue
                                                    upperThreshold:self.upperThreshold.stringValue
                                                  showIntermediate:(BOOL)self.cpShowIntermediate.selectedSegment
                                                        foreGround:(BOOL)self.cpRunForeground.selectedSegment];
    NSString *prevTitle = sender.title.copy;
    sender.enabled = NO;
    [sender setTitle:@"running"];
    [IMCCellSegmenter runCPSegmentationForeGround:(BOOL)self.cpRunForeground.selectedSegment details:NO onStack:self.trainer.stack withHash:self.trainer.mapPrediction.itemHash withBlock:^{
        [sender setTitle:prevTitle];
        sender.enabled = YES;
        [self showResults:nil];
    } inOwnThread:YES];
}

-(NSString *)maskPath{
    return [NSString stringWithFormat:@"%@/%@_seg_pmap_mask_cells.tiff", self.trainer.stack.workingFolder, self.trainer.mapPrediction.itemHash.copy];
}

-(IBAction)showResults:(NSButton *)sender{
    if(self.maskGenerated){
        self.maskGenerated = nil;
        [sender setTitle:@"4. Show results"];
    }else{
        
        
        if(self.maskGenerated)free(self.maskGenerated);
        self.maskGenerated  = [IMCMasks maskFromFile:[NSURL fileURLWithPath:[self maskPath]] forImageStack:self.trainer.stack];
        [sender setTitle:@"4. Hide results"];
        [self refresh];
    }
}
-(IBAction)addMasksToStack:(NSButton *)sender{
    [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
    [self.trainer saveTrainingMask:self.trainer.trainingNodes.firstObject];
    [self.trainer.mapPrediction savePixelMapPredictions];
    if([[NSFileManager defaultManager]fileExistsAtPath:[self maskPath]])
        [self.trainer.stack getMaskAtURL:[NSURL fileURLWithPath:[self maskPath]]];
}

-(void)dealloc{
    if(self.maskGenerated)free(self.maskGenerated);
}


@end
