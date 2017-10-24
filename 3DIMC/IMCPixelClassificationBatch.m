//
//  IMCCellSegmentationBatch.m
//  3DIMC
//
//  Created by Raul Catena on 3/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelClassificationBatch.h"
#import "IMCNodeWrapper.h"
#import "IMCPixelTraining.h"
#import "IMCPixelTrainer.h"
#import "IMCImageStack.h"
#import "IMCPixelMap.h"

@interface IMCPixelClassificationBatch ()

@end

@implementation IMCPixelClassificationBatch

-(instancetype)init{
    
    return [self initWithWindowNibName:NSStringFromClass([IMCPixelClassificationBatch class]) owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.trainingsTableView == tableView?[self.delegate allTrainings].count:[self.delegate allStacks].count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSArray *ret = self.trainingsTableView == tableView?[self.delegate allTrainings]:[self.delegate allStacks];
    IMCNodeWrapper * node = ret[row];
    return node.itemName;
}
-(void)refreshTabless:(id)sender{
    [self.stacksTableView reloadData];
    [self.trainingsTableView reloadData];
}
-(void)startBatch:(NSButton *)sender{
    sender.enabled = NO;
    
    NSMutableArray *selectedTrainings = @[].mutableCopy;
    
    NSMutableArray *trainingsLoaded = @[].mutableCopy;
    NSMutableArray *stacksLoaded = @[].mutableCopy;
    
    [self.trainingsTableView.selectedRowIndexes.copy enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        IMCPixelTraining *training = [[self.delegate allTrainings]copy][index];
        if([[NSFileManager defaultManager]fileExistsAtPath:training.absolutePath]){
            [selectedTrainings addObject:training];
            [trainingsLoaded addObject:[NSNumber numberWithBool:training.isLoaded]];
            [stacksLoaded addObject:training.imageStack];
            if(!training.isLoaded)
                [training loadBuffer];
            while (!training.isLoaded);
            if(!training.imageStack.isLoaded)
                [training.imageStack loadLayerDataWithBlock:nil];
            while (!training.imageStack.isLoaded);
        }
    }];
    
    NSInteger howmanystacks = self.stacksTableView.selectedRowIndexes.count;
    __block NSInteger counter = 0;
    dispatch_queue_t aQ = dispatch_queue_create("BatPC", NULL);
    dispatch_async(aQ, ^{
        __block IMCPixelTrainer * trainer;
        
        NSArray *allStacks = [self.delegate allStacks].copy;
        
        [self.stacksTableView.selectedRowIndexes.copy enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            
            IMCImageStack *stack = allStacks[index];
            BOOL wasLoaded = stack.isLoaded;
            
            if(!trainer){
                trainer  = [[IMCPixelTrainer alloc]initWithStack:stack andTrainings:selectedTrainings];
                if(![trainer trainRandomForests])
                    return;
            }
            else
                trainer.stack = stack;
            trainer.isSegmentation = [(IMCPixelTraining *)selectedTrainings.firstObject isSegmentation];
            
            trainer.theHash = nil;
            
            [stack.fileWrapper checkAndCreateWorkingFolder];
            
            [trainer loadDataInRRFF];
            [trainer classifyPixels];
            [trainer.mapPrediction savePixelMapPredictions];
            
            if(!wasLoaded && ![stacksLoaded containsObject:stack])//Close the stack if it was not opened but making sure it is not one of the stacks involved in the training
                dispatch_async(dispatch_get_main_queue(), ^{
                    [stack unLoadLayerDataWithBlock:nil];
                });
            
            counter++;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressBar.doubleValue = counter/(float)howmanystacks;
                if(self.progressBar.doubleValue == 1.0)
                    sender.enabled = YES;
            });
        }];
    });
}



@end
