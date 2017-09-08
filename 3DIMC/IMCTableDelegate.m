//
//  IMCTableDelegate.m
//  3DIMC
//
//  Created by Raul Catena on 2/25/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCTableDelegate.h"
#import "IMCComputationOnMask.h"
#import "NSArray+Statistics.h"
#import "IMCPixelClassification.h"

@interface IMCTableDelegate()
@property (nonatomic, strong) NSMutableArray *amountsPerFile;
@end

@implementation IMCTableDelegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if(!self.amountsPerFile)self.amountsPerFile = @[].mutableCopy;
    [self.amountsPerFile removeAllObjects];
    NSInteger inter = 0;
    for (IMCComputationOnMask *compo in [self.delegate computations]) {
        [self.amountsPerFile addObject:[NSNumber numberWithInteger:[compo segmentedUnits]]];
        inter+= [self.amountsPerFile.lastObject integerValue];
    }
    return inter;
}

-(void)rebuildTable{
    NSTableView *tableView = [self.delegate tableViewEvents];
    
    IMCComputationOnMask *winner = [self.delegate computations].firstObject;
    for (IMCComputationOnMask *compo in [self.delegate computations]) {
        if(compo.channels.count > winner.channels.count)
            winner = compo;
    }
    
    while([[tableView tableColumns] count] > 0) {
        NSTableColumn *col = [[tableView tableColumns]lastObject];
        [tableView removeTableColumn:col];
    }
    
    NSTableColumn* aColumn = [[NSTableColumn alloc] initWithIdentifier:@"CompId"];
    aColumn.title = @"CompId";
    [tableView addTableColumn:aColumn];
    
    for (NSString *ident in winner.channels) {
        NSTableColumn* newColumn = [[NSTableColumn alloc] initWithIdentifier:ident.copy];
        newColumn.title = ident.copy;
        [tableView addTableColumn:newColumn];
    }
    
    [tableView reloadData];
}

-(IMCComputationOnMask *)whichComp:(NSInteger)row{
    if(self.amountsPerFile.count != [self.delegate computations].count)
        return nil;
    
    NSInteger sum = 0;
    NSInteger index = 0;
    do {
        sum += [self.amountsPerFile[index]integerValue];
        index++;
    } while (row >= sum);
    
    return [self.delegate computations][index - 1];
}
-(NSInteger)offSetForRow:(NSInteger)comp{
    NSInteger offset = 0;
    for (NSInteger i = 0; i < comp; i++) {
        offset += [[self.delegate computations][i]mask].numberOfSegments;
    }
    return offset;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    IMCComputationOnMask *comp = [self whichComp:row];
    if(!comp || !comp.isLoaded)return @"";
    float **data = comp.computedData;
    NSInteger indexCol = [[tableView tableColumns]indexOfObject:tableColumn];
    
    if(indexCol == 0)
        return [NSNumber numberWithInteger:[[self.delegate computations]indexOfObject:comp]];
    return [NSNumber numberWithFloat:data[indexCol - 1][row - [self offSetForRow:[[self.delegate computations]indexOfObject:comp]]]];
}

@end
