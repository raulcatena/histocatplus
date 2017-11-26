//
//  IMCCellClassificationBatch.m
//  3DIMC
//
//  Created by Raul Catena on 3/13/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellClassificationBatch.h"
#import "IMCNodeWrapper.h"
#import "IMCMaskTraining.h"
#import "IMCCellTrainer.h"
#import "IMCComputationOnMask.h"
#import "IMCPixelClassification.h"

@interface IMCCellClassificationBatch ()

@end

@implementation IMCCellClassificationBatch

-(instancetype)init{
    
    return [self initWithWindowNibName:NSStringFromClass([IMCCellClassificationBatch class]) owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.trainingsTableView == tableView?[self.delegate allCellTrainings].count:[self.delegate allComputations].count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSArray *ret = self.trainingsTableView == tableView?[self.delegate allCellTrainings]:[self.delegate allComputations];
    IMCNodeWrapper * node = ret[row];
    return node.itemName;
}
-(void)refreshTabless:(id)sender{
    [self.trainingsTableView reloadData];
    [self.computationsTableView reloadData];
}
-(void)startBatch:(NSButton *)sender{
    
    sender.enabled = NO;
    
    NSMutableArray *selectedTrainings = @[].mutableCopy;
    
    NSMutableArray *trainingsLoaded = @[].mutableCopy;
    NSMutableArray *stacksLoaded = @[].mutableCopy;
    
    [self.trainingsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        IMCMaskTraining *training = [self.delegate allCellTrainings][index];
        [selectedTrainings addObject:training];
        [trainingsLoaded addObject:[NSNumber numberWithBool:training.isLoaded]];
        [stacksLoaded addObject:[NSNumber numberWithBool:training.computation.isLoaded]];
        
        //Open mask
        if(!training.computation.mask.isLoaded)
            [training.computation.mask loadLayerDataWithBlock:nil];
        while (!training.computation.mask.isLoaded);
        
        //Open computation
        if(!training.computation.isLoaded)
            [training.computation loadLayerDataWithBlock:nil];
        while (!training.computation.isLoaded);
        
        //Open training
        if(!training.isLoaded)
            [training loadBuffer];
        while (!training.isLoaded);
    }];
    
    
    
    NSInteger howmanystacks = self.computationsTableView.selectedRowIndexes.count;
    __block NSInteger counter = 0;
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        __block IMCCellTrainer * trainer;
        
        [self.computationsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            
            IMCComputationOnMask *computation = [self.delegate allComputations][index];
            
            [computation.mask openIfNecessaryAndPerformBlock:^{
                [computation openIfNecessaryAndPerformBlock:^{
                    if(!trainer){
                        trainer  = [[IMCCellTrainer alloc]initWithComputation:computation andTrainings:selectedTrainings];
                        if(![trainer trainRandomForests])
                            return;
                    }
                    else
                        trainer.computation = computation;
                    
                    trainer.theHash = nil;
                    
                    [trainer loadDataInRRFF];
                    [trainer classifyCells];
                    [trainer addResultsToComputation];
                    counter++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressBar.doubleValue = counter/(float)howmanystacks;
                        if(self.progressBar.doubleValue == 1.0)
                            sender.enabled = YES;
                    });
                }];
            }];
        }];
    });
}

@end
