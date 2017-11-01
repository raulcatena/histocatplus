//
//  IMCWorkspaceSelector.m
//  3DIMC
//
//  Created by Raul Catena on 2/17/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCWorkspaceSelector.h"
#import "IMCFileWrapper.h"
#import "IMCNodeWrapper.h"
#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"
#import "IMCPixelTraining.h"
#import "IMCPixelClassification.h"
#import "IMCPixelMap.h"
#import "IMCComputationOnMask.h"
#import "IMCWorkSpace.h"
#import "IMC3DHandler.h"
#import "IMC3DMask.h"


@implementation IMCWorkspaceSelector

#pragma mark OutlineView

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if(self.parent.whichTableCoordinator.indexOfSelectedItem == 1)return NO;
    if ([item isKindOfClass:[IMCFileWrapper class]])return [(IMCFileWrapper *)item isSoftLoaded];
    if ([item isKindOfClass:[IMCNodeWrapper class]])return [[(IMCNodeWrapper *)item children]count] > 0?YES:NO;
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    //item is nil when the outline view wants to inquire for root level items
    if (item == nil){
        
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 0)
            return self.parent.dataCoordinator.fileWrappers.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 1)
            return self.parent.dataCoordinator.inOrderImageWrappers.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 2)
            return self.parent.dataCoordinator.pixelTrainings.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 3)
            return self.parent.dataCoordinator.pixelMaps.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 4)
            return self.parent.dataCoordinator.masks.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 5)
            return self.parent.dataCoordinator.computations.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 6)
            return self.parent.dataCoordinator.maskTrainings.count;
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 7)
            return self.parent.dataCoordinator.threeDNodes.count;
    }
    return [[(IMCFileWrapper *)item children]count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    //item is nil when the outline view wants to inquire for root level items
    if (item == nil){
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 0)
            return [self.parent.dataCoordinator.fileWrappers objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 1)
            return [self.parent.dataCoordinator.inOrderImageWrappers objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 2)
            return [self.parent.dataCoordinator.pixelTrainings objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 3)
            return [self.parent.dataCoordinator.pixelMaps objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 4)
            return [self.parent.dataCoordinator.masks objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 5)
            return [self.parent.dataCoordinator.computations objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 6)
            return [self.parent.dataCoordinator.maskTrainings objectAtIndex:index];
        if(self.parent.whichTableCoordinator.indexOfSelectedItem == 7)
            return [self.parent.dataCoordinator.threeDNodes objectAtIndex:index];
    }
    if ([item isKindOfClass:[IMCNodeWrapper class]])
        return [[(IMCNodeWrapper *)item children]objectAtIndex:index];
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(IMCNodeWrapper *)item{
    if ([[theColumn identifier] isEqualToString:@"colA"])
        return item.itemName;
    else
        return item.itemSubName;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification{
    
    NSArray *arrs = @[self.parent.inScopeImages,
                      self.parent.inScopeFiles,
                      self.parent.inScopeMasks,
                      self.parent.inScopePanoramas,
                      self.parent.inScopeComputations,
                      self.parent.involvedStacksForMetadata];
    
    for(NSMutableArray *arr in arrs)
        [arr removeAllObjects];
    
    self.parent.inScopeImage = nil;
    self.parent.inScopeMask = nil;
    self.parent.inScopeComputation = nil;
    self.parent.inScope3DMask = nil;
    
    //Test for panoramas and masks first
    NSMutableArray *array = @[].mutableCopy;
    [self.parent.filesTree.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        id anobj = [self.parent.filesTree itemAtRow:idx];
        
        if([anobj isMemberOfClass:[IMCPanoramaWrapper class]])
            if([(IMCPanoramaWrapper *)anobj isPanorama])
                [self.parent.inScopePanoramas addObject:[(IMCPanoramaWrapper *)anobj panoramaImage]];
            
        if([anobj isMemberOfClass:[IMCFileWrapper class]])
            [self.parent.inScopeFiles addObject:anobj];
        
        if([anobj isMemberOfClass:[IMCPixelClassification class]]){
            [self.parent.inScopeMasks addObject:anobj];
            if(idx == self.parent.filesTree.selectedRow)
                self.parent.inScopeMask = anobj;
        }
        if([anobj isMemberOfClass:[IMCComputationOnMask class]]){
            [self.parent.inScopeComputations addObject:anobj];
            if(idx == self.parent.filesTree.selectedRow)
                self.parent.inScopeComputation = anobj;
        }
        if([anobj isMemberOfClass:[IMC3DMask class]]){
            if(idx == self.parent.filesTree.selectedRow)
                self.parent.inScope3DMask = anobj;
        }
        
        //Now Imagestacks
        IMCNodeWrapper *node = anobj;
        while (node.children.count > 0) {
            if([anobj isMemberOfClass:[IMCImageStack class]] || [anobj isMemberOfClass:[IMCPixelMap class]])
                break;
            node = node.children.firstObject;
        }
        if([node isMemberOfClass:[IMCImageStack class]] || [node isMemberOfClass:[IMCPixelMap class]]){
            BOOL anyFound = NO;
            for (IMCImageStack *stck in node.parent.children) {
                if(stck == [self.parent.filesTree itemAtRow:idx]){
                    if(![array containsObject:stck]){
                        [array addObject:stck];
                        anyFound = YES;
                    }
                }
            }
            if(anyFound == NO)
                self.parent.inScopeImage = (IMCImageStack *)node.parent.children.firstObject;
            
            if(idx == self.parent.filesTree.selectedRow)
                self.parent.inScopeImage = (IMCImageStack *)node;
            
            if(node.parent.children.count > 1)
                [self.parent.filesTree expandItem:[self.parent.filesTree itemAtRow:[self.parent.filesTree selectedRow]]];
            
        }
        
    }];

    for (IMCImageStack *stack in array)
        if(![self.parent.inScopeImages containsObject:stack]){
            [self.parent.inScopeImages addObject:stack];
            [self.parent.involvedStacksForMetadata addObject:stack];
        }
    for (IMCComputationOnMask *comp in self.parent.inScopeComputations)
        if(![self.parent.involvedStacksForMetadata containsObject:comp.mask.imageStack])
            [self.parent.involvedStacksForMetadata addObject:comp.mask.imageStack];
    for (IMCPixelClassification *mask in self.parent.inScopeMasks)
        if(![self.parent.involvedStacksForMetadata containsObject:mask.imageStack])
            [self.parent.involvedStacksForMetadata addObject:mask.imageStack];
    
    
    [self.parent refresh];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    
    if([item isKindOfClass:[IMCNodeWrapper class]]){
        IMCNodeWrapper *node = (IMCNodeWrapper *)item;
        if([node hasChanges] == YES)
            [cell setTextColor:[NSColor redColor]];
        else if(!node.isLoaded)
            [cell setTextColor:[NSColor colorWithWhite:0.5 alpha:1.0]];
        else
            [cell setTextColor:[NSColor blackColor]];
        if(item == self.parent.inScopeMask || item == self.parent.inScopeImage || item == self.parent.inScope3DMask || item == self.parent.inScopeComputation)
            if(node.isLoaded)
                [cell setTextColor:[NSColor orangeColor]];
        return;
    }
    
    [cell setTextColor:[NSColor colorWithWhite:0.49 alpha:1.0]];
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    if([item isMemberOfClass:[IMCFileWrapper class]] || [tableColumn.identifier isEqualToString:@"colB"])return NO;
    return YES;
}
-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(nullable id)object forTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item{
    if(![item isMemberOfClass:[IMCFileWrapper class]]){
        if([object respondsToSelector:@selector(uppercaseString)])
            if([object length] > 0)
                [(IMCNodeWrapper *)item setItemName:object];
    }
}

#pragma mark TableView

-(IBAction)updateTableView:(NSSegmentedControl *)sender{
    
    self.parent.pushItemUp.hidden = !(self.parent.whichTableCoordinator.indexOfSelectedItem == 1);
    self.parent.pushItemDown.hidden = !(self.parent.whichTableCoordinator.indexOfSelectedItem == 1);
    self.parent.exportCSVButton.hidden = !(self.parent.whichTableCoordinator.indexOfSelectedItem == 5);
    self.parent.exportFCSButton.hidden = !(self.parent.whichTableCoordinator.indexOfSelectedItem == 5);
    
    if(sender == self.parent.whichTableChannels){
        int i = 0;
        for (NSScrollView *tv in @[self.parent.channelsSV, self.parent.channelsCustomSV]) {
            tv.hidden = ((sender.selectedSegment > 1 && i == 0) || (i == 1 && sender.selectedSegment < 2));
            i++;
        }
    }
    [self.parent.filesTree reloadData];
    [self.parent.channels reloadData];
    [self.parent.channelsCustom reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if(self.parent.inScopeComputations.count > 0)
        return self.parent.inScopeComputations.firstObject.channels.count;
    if(self.parent.inScope3DMask)
        return self.parent.inScope3DMask.channels.count;
    return self.parent.inScopeImage?self.parent.inScopeImage.channels.count:0;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if(self.parent.whichTableChannels.selectedSegment == 0)
        if(self.parent.inScopeComputations.count > 0)
            return self.parent.inScopeComputations.firstObject.channels[row];
    
    if(self.parent.inScope3DMask)
        return self.parent.inScope3DMask.channels[row];
    
    if(self.parent.whichTableChannels.selectedSegment == 1)
        if(self.parent.inScopeComputations.count > 0)
            return self.parent.inScopeComputations.firstObject.originalChannels[row];
    
    if(self.parent.whichTableChannels.selectedSegment == 0)
        return self.parent.inScopeImage?[self.parent.inScopeImage.channels objectAtIndex:MIN(row, self.parent.inScopeImage.channels.count - 1)]:@"";
    
    return self.parent.inScopeImage?[self.parent.inScopeImage.origChannels objectAtIndex:row]:@"";
    
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if(self.parent.inScope3DMask)
        [self.parent.inScope3DMask passToHandlerChannels:self.parent.channels.selectedRowIndexes];
    if(!self.parent.inOrderIndexes)
        self.parent.inOrderIndexes = @[].mutableCopy;
    [General orderIndexesUponSelection:self.parent.inOrderIndexes indexes:self.parent.channels.selectedRowIndexes];
    if(![self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_DATAT])[self.parent refresh];
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    for (IMCChannelWrapper *ch in self.parent.channelsInScopeForPlotting)
        if(ch.index == row){
            [cell setTextColor:[NSColor orangeColor]];
            return;
        }
    [cell setTextColor:[NSColor blackColor]];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return (self.parent.whichTableChannels.selectedSegment == 0);
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if (tableView == self.parent.channels && ![[tableColumn identifier]isEqualToString:@"colA"]) {
        if (row < self.parent.inScopeComputation.channels.count && self.parent.inScopeComputation){
            for (IMCComputationOnMask *comp in self.parent.inScopeComputations.copy)
                if(comp.channels.count > row)
                    [comp.channels replaceObjectAtIndex:row withObject:object];
            //[self.parent.inScopeComputation.channels replaceObjectAtIndex:row withObject:object];
        }
        
        if (row < self.parent.inScopeImage.channels.count && !self.parent.inScopeComputation)
            for (IMCImageStack *stack in self.parent.inScopeImages.copy) {
                if(stack.channels.count > row)
                    [stack.channels replaceObjectAtIndex:row withObject:object];
            //[self.parent.inScopeImage.channels replaceObjectAtIndex:row withObject:object];
        }
    }
}

#pragma mark Contextual menus

-(NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows{
    NSMenu *menu = [[NSMenu alloc]initWithTitle:@""];
    if(aTableView == self.parent.filesTree){
        NSMutableArray *addingTitles = @[].mutableCopy;
        NSMutableArray *addingSelectors = @[].mutableCopy;
        
        __block BOOL generFuncs = NO;
        __block BOOL filePanFuncs = NO;
        __block BOOL stackFuncs = NO;
        __block BOOL maskFuncs = NO;
//        __block BOOL trainFuncs = NO;
//        __block BOOL mapsFuncs = NO;
        __block BOOL compFuncs = NO;
        
        [addingTitles addObjectsFromArray:@[@"Load", @"Close"]];
        [addingSelectors addObjectsFromArray:@[@"openNodes:", @"closeNodes:"]];
        
        [rows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            IMCNodeWrapper * item = [self.parent.filesTree itemAtRow:idx];
            if(([item isMemberOfClass:[IMCFileWrapper class]] || [item isMemberOfClass:[IMCPanoramaWrapper class]] || [item isMemberOfClass:[IMCImageStack class]]) && !generFuncs){
                
                [addingTitles addObjectsFromArray:@[
                                                    [NSString stringWithFormat:@"Remove file%@...", rows.count > 1?@"s":@""],
                                                    [NSString stringWithFormat:@"Save file%@...", rows.count > 1?@"s":@""],
                                                    [NSString stringWithFormat:@"Convert file%@ to TIFF...", rows.count > 1?@"s":@""],
                                                    @"Add channels from TSV file (TSV or TXT)...",
                                                    ]];
                if(!VIEWER_ONLY && !VIEWER_HISTO)[addingTitles addObject:@"Add to 3D render..."];
                [addingSelectors addObjectsFromArray:@[
                                                       @"removeFiles:",
                                                       @"saveFiles:",
                                                       @"tiffConvert:",
                                                       @"addChannelsFromTSV:",
                                                       ]];
                if(!VIEWER_ONLY && !VIEWER_HISTO)[addingSelectors addObject:@"addBuffersForStackImages:"];
                
                generFuncs = YES;
            }else{
                if(![addingTitles containsObject:@"Remove"]){
                    [addingTitles addObject:@"Remove"];
                    [addingSelectors addObject:@"removeNodes:"];
                }
            }
            
            if(([item isMemberOfClass:[IMCFileWrapper class]] || [item isMemberOfClass:[IMCPanoramaWrapper class]]) && !filePanFuncs){
                [addingTitles addObject:@"Reload panoramas"];
                [addingSelectors addObject:@"reloadPanoramas:"];
                
                filePanFuncs = YES;
            }
//            if([item isMemberOfClass:[IMCPixelTraining class]] && !trainFuncs){
//                [addingTitles addObject:@"Remove training..."];
//                [addingSelectors addObject:@"removeTraining:"];
//                
//                trainFuncs = YES;
//            }
//            if([item isMemberOfClass:[IMCPixelMap class]] && !mapsFuncs){
//                [addingTitles addObject:@"Remove map..."];
//                [addingSelectors addObject:@"removeMap:"];
//                
//                mapsFuncs = YES;
//            }
            if([item isMemberOfClass:[IMCImageStack class]] && !stackFuncs && item.isLoaded){
                [addingTitles addObject:@"Import mask (TIF or MAT)..."];
                [addingSelectors addObject:@"importMask:"];
                
                stackFuncs = YES;
            }
            if([item isMemberOfClass:[IMCPixelClassification class]] && !maskFuncs && item.isLoaded){
                NSArray *titles = @[@"Load Mask...", @"Remove Mask...",
                                    [NSString stringWithFormat:@"Add features from Cell Profiler file..."],
                                    [NSString stringWithFormat:@"Extract Features For Mask..."]
                                    ];
                NSArray *selectors = @[@"loadMask:", @"removeMask:", @"addFeaturesFromCP:", @"extractFeaturesForMask:"];
                
                IMCPixelClassification *mask = (IMCPixelClassification *)item;
                if([mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_CELL]boolValue] == YES && [mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DUAL]boolValue] == NO){
                    titles = [titles arrayByAddingObject:@"Add nuclear mask..."];
                    selectors = [selectors arrayByAddingObject:@"importNuclearMask:"];
                }
                if([mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_THRESHOLD]boolValue] == YES){
                    titles = [titles arrayByAddingObject:@"Edit mask..."];
                    selectors = [selectors arrayByAddingObject:@"editThresholdMask:"];
                }
                if([mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_PAINTED]boolValue] == YES){
                    titles = [titles arrayByAddingObject:@"Edit mask..."];
                    selectors = [selectors arrayByAddingObject:@"editPaintedMask:"];
                }
                
                [addingTitles addObjectsFromArray:titles];
                [addingSelectors addObjectsFromArray:selectors];
                
                maskFuncs = YES;
            }
            if([item isMemberOfClass:[IMCComputationOnMask class]] && !compFuncs && item.isLoaded){
                
                NSArray *titles = @[@"Export FCS file...",
                                    @"Add features from Cell Profiler file...",
                                    //@"Convert to mask"
                                    ];
                NSArray *selectors = @[@"exportFCSFile...",
                                       @"addFeaturesFromCP:",
                                    //   @"convertToMask:"
                                    ];
                [addingTitles addObjectsFromArray:titles];
                [addingSelectors addObjectsFromArray:selectors];
    
                compFuncs = YES;
            }
        }];
        [addingTitles addObject:@"Copy json dictionary"];
        [addingSelectors addObject:@"copyJsonForNode:"];
        
        
        for (NSString *title in addingTitles) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title
                                                              action:NSSelectorFromString([addingSelectors objectAtIndex:[addingTitles indexOfObject:title]]) keyEquivalent:@""];
            menuItem.tag = [addingTitles indexOfObject:title];
            [menu addItem:menuItem];
            
            //if([title hasPrefix:@"Add to 3D render"] && self.parent.threeDHandler.isReady == NO)menuItem.enabled = NO;
        }
    }
    if(aTableView == self.parent.channels){
        
        NSMutableArray *titles = @[[NSString stringWithFormat:@"Delete Channel%@...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Add Channel%@ insert after last selected...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Add Channel%@ insert at beggining...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Add Channel%@ insert at end...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Multiply Channel%@ insert after last selected...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Multiply Channel%@ insert at beggining...", rows.count > 1?@"s":@""],
                            [NSString stringWithFormat:@"Multiply Channel%@ insert at end...", rows.count > 1?@"s":@""],
                            @"Apply settings to all images selected...",
                            @"Apply settings adjusting MAX to all images selected...",
                            @"Apply colors to all images selected...",
                            @"Import channel names from TSV file...",
                            @"Add Metric to Metadata...",
                            ].mutableCopy;
        
        if(!VIEWER_ONLY && !VIEWER_HISTO)[titles addObject:@"Add to 3D render..."];
        
        NSMutableArray *selectors = @[@"deleteChannels:", @"addChannelsInline:", @"addChannelsBeggining:", @"addChannelsEnd:", @"multiplyChannelsInline:", @"multiplyChannelsBeggining:", @"multiplyChannelsEnd:", @"applySettings:", @"applySettingsWithMax:", @"applyColors:", @"addChannelsFromTSV:", @"calcToMetadata:"
                               ].mutableCopy;
        
        if(!VIEWER_ONLY && !VIEWER_HISTO)[selectors addObject:@"addBuffersForStackImages:"];
        
        for (NSString *title in titles) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title
                                                              action:NSSelectorFromString([selectors objectAtIndex:[titles indexOfObject:title]]) keyEquivalent:@""];
            menuItem.tag = [titles indexOfObject:title];
            [menu addItem:menuItem];
            
            if([title hasPrefix:@"Add to 3D render"] && self.parent.threeDHandler.isReady == NO)menuItem.enabled = NO;
        }
    }
    return menu;
}

@end
