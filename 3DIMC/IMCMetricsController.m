//
//  IMCMetricsController.m
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMetricsController.h"
#import "IMCWorkSpace.h"
#import "IMCImageStack.h"
#import "IMCMetric.h"

@implementation IMCMetricsController

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    NSInteger channels = 0;
    if(tableView == self.parent.analyticsMetrics)
        channels = self.parent.dataCoordinator.metrics.count;
    
    if(tableView == self.parent.analyticsChannels)
        channels = self.parent.inScopeImage.channels.count;
    
    if(tableView == self.parent.analyticsFilterChannels)
        channels = self.parent.inScopeImage.channels.count;
    
    return channels;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *cellString;
    
    if(tableView == self.parent.analyticsMetrics)
        cellString = [NSString stringWithFormat:@"%@ %@", self.parent.dataCoordinator.metrics[row][JSON_METRIC_NAME], self.parent.dataCoordinator.metrics[row][JSON_METRIC_TYPE]];
    
    if(tableView == self.parent.analyticsChannels)
        cellString = self.parent.inScopeImage.channels[row];
    
    if(tableView == self.parent.analyticsFilterChannels)
        cellString = self.parent.inScopeImage.channels[row];
    
    return cellString?cellString:@"";
}

-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return (tableView == self.parent.analyticsMetrics);
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSMutableDictionary *dict = [self.parent.dataCoordinator.metrics objectAtIndex:row];
    dict[JSON_METRIC_NAME] = object;
}

-(void)refreshTables{
    [self.parent.analyticsMetrics reloadData];
    [self.parent.analyticsChannels reloadData];
    [self.parent.analyticsFilterChannels reloadData];
    [self.parent.analyticsResults reloadData];
}

-(void)addMetric{
    NSString *name = [IMCUtils input:@"Name for metric" defaultValue:@"New name"];
    if(name){
        
        NSInteger option = [IMCUtils inputOptions:[IMCMetric allOptions] prompt:@"Select the type of measurement"];
        if(option != NSNotFound){
            IMCMetric *metric = [[IMCMetric alloc]initWithMetricType:[IMCMetric allOptions][option] name:name primaryChannels:self.parent.analyticsChannels.selectedRowIndexes filterChannels:self.parent.analyticsFilterChannels.selectedRowIndexes isAnd:YES];
            NSMutableDictionary *dict = [metric generateDictionary];
            [self.parent.dataCoordinator.metrics addObject:dict];
            [self.parent.analyticsMetrics reloadData];
        }
    }
}

-(void)removeMetric{
    [self.parent.dataCoordinator.metrics removeObjectAtIndex:self.parent.analyticsMetrics.selectedRow];
    [self refreshTables];
}

@end
