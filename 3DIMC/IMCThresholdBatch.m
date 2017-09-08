//
//  IMCThresholdBatch.m
//  3DIMC
//
//  Created by Raul Catena on 3/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCThresholdBatch.h"
#import "IMCNodeWrapper.h"
#import "IMCPixelClassification.h"
#import "IMCThresholder.h"

@interface IMCThresholdBatch ()

@end

@implementation IMCThresholdBatch

-(instancetype)init{
    return [self initWithWindowNibName:NSStringFromClass([IMCThresholdBatch class]) owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.thresholdedTableView == tableView?[self.delegate allThresholdPixClassifications].count:[self.delegate allStacks].count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSArray *ret = self.thresholdedTableView == tableView?[self.delegate allThresholdPixClassifications]:[self.delegate allStacks];
    IMCNodeWrapper * node = ret[row];
    return node.itemName;
}
-(void)refreshTabless:(id)sender{
    [self.stacksTableView reloadData];
    [self.thresholdedTableView reloadData];
}
-(void)startBatch:(NSButton *)sender{
    sender.enabled = NO;
    
    IMCPixelClassification *mask = [self.delegate allThresholdPixClassifications][self.thresholdedTableView.selectedRow];
    IMCThresholder *doer = [[IMCThresholder alloc]init];
    doer.label = mask.itemSubName;
    doer.mask = mask;//Capture the settings from selected mask
    
    NSInteger howmanystacks = self.stacksTableView.selectedRowIndexes.count;
    __block NSInteger counter = 0;
    dispatch_queue_t aQ = dispatch_queue_create("BatPC", NULL);
    dispatch_async(aQ, ^{
        
        [self.stacksTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            
            IMCImageStack *stack = [self.delegate allStacks][index];
            BOOL wasLoaded = stack.isLoaded;
            if(!wasLoaded)
                [stack loadLayerDataWithBlock:nil];
            while(!stack.isLoaded);
            
            doer.mask = nil;//So that a new one is created everytime
            doer.stack = stack;
            [doer generateBinaryMask];
            [doer saveMask];
            if(!wasLoaded)
                [stack unLoadLayerDataWithBlock:nil];
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
