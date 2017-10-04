//
//  IMCMetadataTableDelegate.m
//  3DIMC
//
//  Created by Raul Catena on 6/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMetadataTableDelegate.h"
#import "IMCLoader.h"
#import "IMCImageStack.h"
#import "IMCPixelMap.h"

@implementation IMCMetadataTableDelegate



-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    
    return [self.delegate involvedStacksForMetadata].count;
}

-(void)rebuildTable{
    NSTableView *tableView = [self.delegate metadataTable];
    
//    IMCComputationOnMask *winner = [self.delegate computations].firstObject;
//    for (IMCComputationOnMask *compo in [self.delegate computations]) {
//        if(compo.channels.count > winner.channels.count)
//            winner = compo;
//    }
    
    while([[tableView tableColumns] count] > 0) {
        NSTableColumn *col = [[tableView tableColumns]lastObject];
        [tableView removeTableColumn:col];
    }
    
    NSArray *defaultColumns = METADATA_GIVEN_COLUMNS;
    for (NSString *title in defaultColumns) {
        NSTableColumn* aColumn = [[NSTableColumn alloc] initWithIdentifier:title];
        aColumn.title = title;
        [tableView addTableColumn:aColumn];
    }
    IMCLoader *loader = [self.delegate dataCoordinator];
    for (NSString *key in loader.metadata[JSON_METADATA_KEYS]) {
        NSTableColumn* newColumn = [[NSTableColumn alloc] initWithIdentifier:key.copy];
        newColumn.title = key.copy;
        [tableView addTableColumn:newColumn];
    }
    
    [tableView reloadData];
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if ([tableView columnWithIdentifier:[tableColumn identifier]] > METADATA_GIVEN_COLUMNS_OFFSET - 1) {
        IMCLoader *loader = [self.delegate dataCoordinator];
        IMCImageStack *stack = [self.delegate.involvedStacksForMetadata objectAtIndex:row];
        NSString *key = loader.metadata[JSON_METADATA_KEYS][[tableView columnWithIdentifier:tableColumn.identifier] - METADATA_GIVEN_COLUMNS_OFFSET];
        NSMutableDictionary *dict = [loader metadataForImageStack:stack];
        dict[key] = object;
        [tableView reloadData];
    }
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    
    IMCImageStack *stack = [self.delegate.involvedStacksForMetadata objectAtIndex:row];
    switch ([tableView columnWithIdentifier:tableColumn.identifier]) {
        case 0:
            return stack.itemName;
            break;
        case 1:
            return stack.itemHash;
            break;
        case 2:
            return stack.fileWrapper.relativePath;
            break;
        default:
            break;
    }
    IMCLoader *loader = [self.delegate dataCoordinator];
    if(!tableColumn.identifier)
        return @"";
    NSString *key = loader.metadata[JSON_METADATA_KEYS][[tableView columnWithIdentifier:tableColumn.identifier] - METADATA_GIVEN_COLUMNS_OFFSET];
    if([stack isMemberOfClass:[IMCPixelMap class]])
        stack = [(IMCPixelMap *)stack imageStack];
    NSDictionary *dict = [self.delegate.dataCoordinator metadataForImageStack:stack];
    return dict[key]?dict[key]:@"";
}
-(NSArray <IMCImageStack *>*)selectedStacks{
    NSMutableArray *arr = @[].mutableCopy;
    NSArray *stacks = [self.delegate involvedStacksForMetadata].copy;
    NSIndexSet *indexes = self.delegate.metadataTable.selectedRowIndexes.copy;
    [stacks enumerateObjectsAtIndexes:indexes options:NSEnumerationConcurrent usingBlock:^(IMCImageStack *stack, NSUInteger idx, BOOL *stop){
        [arr addObject:stack];
    }];
    return arr;
}
@end
