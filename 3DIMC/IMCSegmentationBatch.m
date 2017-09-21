//
//  IMCSegmentationBatch.m
//  3DIMC
//
//  Created by Raul Catena on 3/6/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCSegmentationBatch.h"
#import "IMCNodeWrapper.h"
#import "IMCPixelMap.h"
#import "IMCCellSegmenter.h"

@interface IMCSegmentationBatch ()

@end

@implementation IMCSegmentationBatch

-(instancetype)init{
    
    return [self initWithWindowNibName:NSStringFromClass([IMCSegmentationBatch class]) owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.delegate allMapsForSegmentation].count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    IMCNodeWrapper * node = [self.delegate allMapsForSegmentation][row];
    return node.itemName;
}
-(void)refreshTabless:(id)sender{
    [self.mapsTableView reloadData];
}
-(void)startBatchOld:(NSButton *)sender{
    
    NSInteger howmanymaps = self.mapsTableView.selectedRowIndexes.count;
    __block NSInteger counter = 0;
    self.progressBar.doubleValue = counter;
        
    dispatch_queue_t aQ = dispatch_queue_create("BatPC", NULL);
    dispatch_async(aQ, ^{
        [self.mapsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            IMCPixelMap *map = [self.delegate allMapsForSegmentation][index];
            
//            if([[NSFileManager defaultManager]fileExistsAtPath:[map.workingFolder stringByAppendingPathComponent:map.relativePath]]){
                if(!map.isLoaded)
                    [map loadLayerDataWithBlock:nil];
            
                while (!map.isLoaded);
            map.isSegmentation = YES;
                [map saveColorizedPixelMapPredictions];
                
                [IMCCellSegmenter saveCellProfilerPipelineWithImageWithWf:map.workingFolder hash:map.itemHash minCellDiam:self.minCellDiam.stringValue maxCellDiam:self.maxCellDiam.stringValue lowThreshold:self.lowerThreshold.stringValue upperThreshold:self.upperThreshold.stringValue showIntermediate:YES foreGround:NO];
                
                NSString *maskPath = [NSString stringWithFormat:@"%@/%@_seg_pmap_mask_cells.tiff", map.workingFolder, map.itemHash.copy];
                
                NSLog(@"MaskPath %@", maskPath);
                
                [IMCCellSegmenter runCPSegmentationForeGround:NO details:NO onStack:map.imageStack withHash:map.itemHash withBlock:^{
                    counter++;
                    self.progressBar.doubleValue = counter/(float)howmanymaps;
                    [map.imageStack getMaskAtURL:[NSURL fileURLWithPath:maskPath]];
                } inOwnThread:NO];
            //}
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.progressBar.doubleValue = counter/(float)howmanymaps;
//            });
        }];
    });
}

-(void)startBatch:(NSButton *)sender{
    sender.enabled = NO;
    
    NSInteger howmanymaps = self.mapsTableView.selectedRowIndexes.count;
    __block NSInteger counter = 0;
    self.progressBar.doubleValue = counter;
    NSInteger cores = MAX(1, [[NSProcessInfo processInfo]processorCount]/2);
    NSLog(@"____%li available cores", [[NSProcessInfo processInfo] processorCount]);
    __block NSInteger activeProcesses = 0;
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        [self.mapsTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            while (activeProcesses>=cores);
            activeProcesses++;
            IMCPixelMap *map = [self.delegate allMapsForSegmentation][index];
            
            //if([[NSFileManager defaultManager]fileExistsAtPath:map.absolutePath]){
            if(!map.isLoaded)
                [map loadLayerDataWithBlock:nil];
            
            while (!map.isLoaded);
            map.isSegmentation = YES;
            [map saveColorizedPixelMapPredictions];
            
            [IMCCellSegmenter saveCellProfilerPipelineWithImageWithWf:map.workingFolder hash:map.itemHash minCellDiam:self.minCellDiam.stringValue maxCellDiam:self.maxCellDiam.stringValue lowThreshold:self.lowerThreshold.stringValue upperThreshold:self.upperThreshold.stringValue showIntermediate:YES foreGround:NO];
            
            NSString *maskPath = [NSString stringWithFormat:@"%@/%@_seg_pmap_mask_cells.tiff", map.workingFolder, map.itemHash.copy];
            
            dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
            dispatch_async(aQ, ^{
                [IMCCellSegmenter runCPSegmentationForeGround:NO details:NO onStack:map.imageStack withHash:map.itemHash withBlock:^{
                    counter++;
                    self.progressBar.doubleValue = counter/(float)howmanymaps;
                    if(self.progressBar.doubleValue == 1.0)
                        sender.enabled = YES;
                    [map.imageStack getMaskAtURL:[NSURL fileURLWithPath:maskPath]];
                } inOwnThread:NO];
                activeProcesses--;
            });
        }];
    });
    
}

@end
