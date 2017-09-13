//
//  IMCWorkSpaceRefresher.m
//  3DIMC
//
//  Created by Raul Catena on 2/17/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCWorkSpaceRefresher.h"
#import "IMCWorkSpace.h"
#import "IMCImageStack.h"
#import "IMC3DHandler.h"
#import "IMCPanoramaWrapper.h"
#import "IMCPixelTraining.h"
#import "IMCPixelMap.h"
#import "IMCPixelClassification.h"
#import "IMCComputationOnMask.h"
#import "IMCImageGenerator.h"
#import "NSImage+OpenCV.h"
#import "IMCRegistration.h"


@interface IMCWorkSpaceRefresher(){
    BOOL overrideRefresh;
}


@end

@implementation IMCWorkSpaceRefresher

-(void)calculateMemory{
    float mb = 0;
    for (IMCFileWrapper *wrapp in self.parent.dataCoordinator.fileWrappers) {
        for (IMCImageStack *stck in [wrapp allStacks]) {
            mb += [stck usedMegaBytes];
            for(IMCPixelClassification *mask in stck.pixelMasks){
                mb += [mask usedMegaBytes];
                for(IMCComputationOnMask *comp in mask.computationNodes)
                    mb += [comp usedMegaBytes];
            }
            for(IMCPixelMap *map in stck.pixelMaps)
                mb += [map usedMegaBytes];
            for (IMCPixelTraining *train in stck.pixelTrainings)
                mb += [train usedMegaBytes];
        }
    }
    mb += self.parent.threeDHandler.megabytes;
    self.parent.memoryUsage.stringValue = [NSString stringWithFormat:@"Memory usage: %.2f %@", mb > 1024?mb/1024:mb, mb>1024?@"GB":@"MB"];
}

-(void)refresh{
    overrideRefresh = YES;
    
    self.parent.scrollViewBlends.imageView.stacks = 0;
    
    //If mask is selected directly
    self.parent.maskVisualizeSelector.hidden = (self.parent.inScopeMasks.count == 0 && self.parent.inScopeComputations.count == 0);
    
    //If mask involved is dual...
    self.parent.maskPartsSelector.hidden = YES;
    if(self.parent.inScopeMasks.count > 0 || self.parent.inScopeComputations.count > 0){
        for (IMCPixelClassification *mask in self.parent.inScopeMasks)
            if([mask isDual]){
                self.parent.maskPartsSelector.hidden = NO;
                break;
            }
        if(self.parent.maskPartsSelector.hidden){
            for (IMCComputationOnMask *comp in self.parent.inScopeComputations)
                if([comp.mask isDual]){
                    self.parent.maskPartsSelector.hidden = NO;
                    break;
                }
        }
    }
    
    if(self.parent.inScopePanoramas.count > 0 && [[self.parent.filesTree itemAtRow:self.parent.filesTree.selectedRow] isMemberOfClass:[IMCPanoramaWrapper class]]){
        [self refreshFromImageArray:self.parent.inScopePanoramas];
        IMCPanoramaWrapper *pan = [self.parent.filesTree itemAtRow:self.parent.filesTree.selectedRow];
        NSMutableArray *arr = @[].mutableCopy;
        for(IMCImageStack *im in pan.children)
            [arr addObject:im];
        self.parent.scrollViewBlends.imageView.stacks = arr;
        return;
    }
    
    //Otherwise
    for (NSTableView *tv in @[self.parent.filesTree, self.parent.channels, self.parent.channelsCustom])
        [tv reloadData];
    [self.parent.eventsTable reloadData];//This one goes aside to avoid crash in viewer only version
    
    if(self.parent.inScopeComputations.count > 0)
        if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_DATAT])
            [self.parent.tableDelegate rebuildTable];
    
    if(self.parent.involvedStacksForMetadata.count > 0)
        if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_METAD])
            [self.parent.metadataTableDelegate rebuildTable];
    
    if(self.parent.inScopeComputations.count == 1 && self.parent.inScopeComputation.isLoaded)
        self.parent.statsInfo.stringValue = [self.parent.inScopeComputation descriptionWithIndexes:self.parent.channels.selectedRowIndexes];

    
    self.parent.scrollSubpanels.hidden = YES;
    self.parent.applyTransfomrs.hidden = YES;
    
    [self calculateMemory];
    
    if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_BLEND]){
        [self checkToolsBlendMode];
        [self refreshBlend];
    }
    
    if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_TILES]){
        [self checkToolsTilesMode];
        [self refreshTiles];
    }
//    
//    if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:@"4"]){
//        [self refreshRControls];
//    }
    
    if([self.parent.tabs.selectedTabViewItem.identifier isEqualToString:TAB_ID_ANALYTICS]){
        [self.parent.metricsController refreshTables];
    }
    
    self.parent.channelsTag.stringValue = [NSString stringWithFormat:@"Channels (%li/%li)", self.parent.channels.selectedRowIndexes.count, [self.parent.channels numberOfRows ]];
    self.parent.objectsTag.stringValue = [NSString stringWithFormat:@"Files/Stacks/Masks (%li/%li)", self.parent.filesTree.selectedRowIndexes.count, [self.parent.filesTree numberOfChildrenOfItem:nil]];
}
-(MaskType)maskType{
    MaskType type;
    switch (self.parent.maskPartsSelector.selectedSegment) {
        case 1:
            type = MASK_NUC_PLUS_CYT;
            break;
        case 2:
            type = MASK_NUC;
            break;
        case 3:
            type = MASK_CYT;
            break;
        default:
            type = MASK_ALL_CELL;
            break;
    }
    return type;
}
-(void)refreshBlend{
    overrideRefresh = NO;
    
    if(self.parent.autoRefreshLock.state == NSOffState)
        return;
    
    if(self.parent.inScopeImages.count > 0 || self.parent.inScopeMasks > 0){
        
        NSInteger maxW = 0, maxH = 0;
        for (IMCImageStack *stk in self.parent.inScopeImages.copy) {
            if(stk.width > maxW)maxW = stk.width;
            if(stk.height > maxH)maxH = stk.height;
        }
        for (IMCPixelClassification *stk in self.parent.inScopeMasks.copy) {
            if(stk.imageStack.width > maxW)maxW = stk.imageStack.width;
            if(stk.imageStack.height > maxH)maxH = stk.imageStack.height;
        }
        for (IMCComputationOnMask *comp in self.parent.inScopeComputations.copy) {
            if(comp.mask.imageStack.width > maxW)maxW = comp.mask.imageStack.width;
            if(comp.mask.imageStack.height > maxH)maxH = comp.mask.imageStack.height;
        }
        
        if(maxW == 0 && maxH == 0)return;
        
        float factor = 1 + (self.parent.applyTransfomrs.indexOfSelectedItem * 0.5);
        
        BOOL isAlignment = NO;
        if(self.parent.inScopeImages.count == 2
           && self.parent.channels.selectedRowIndexes.count < 3
           && [self.parent.applyTransfomrs indexOfSelectedItem])
            isAlignment = YES;
        //3D alignment
        
        NSImage *image = [IMCImageGenerator imageForImageStacks:self.parent.inScopeImages.copy
                                               indexes:self.parent.inOrderIndexes.copy
                                      withColoringType:self.parent.colorSpaceSelector.selectedSegment
                                          customColors:[self.parent.customChannelsDelegate collectColors]
                                     minNumberOfColors:3
                                                 width:maxW * factor
                                                height:maxH * factor
                                        withTransforms:(BOOL)self.parent.applyTransfomrs.indexOfSelectedItem
                                                 blend:[IMCBlendModes blendModeForValue:self.parent.multiImageFilters.indexOfSelectedItem]
                                              andMasks:self.parent.inScopeMasks
                                       andComputations:self.parent.inScopeComputations
                                            maskOption:self.parent.maskVisualizeSelector.selectedSegment
                                              maskType:[self maskType]
                                       maskSingleColor:self.parent.scaleBarColor.color
                                       isAlignmentPair:isAlignment
                                           brightField:(BOOL)self.parent.brightFieldEffect.state];
        
        if(self.parent.blur.selectedSegment == 1)
            image = [image gaussianBlurred:(unsigned)self.parent.gaussianBlur.integerValue];
        
        if(overrideRefresh)
            return;
        
        self.parent.scrollViewBlends.imageView.image = image;
        [self scaleAndLegendChannelsBlend];
        [self intensityLegend];
    }
}

-(void)intensityLegend{
    self.parent.colorLegend.hidden = (self.parent.inScopeImages.count != 1);
    self.parent.colorLegend.maxsForLegend = [self.parent.inScopeImage maxesForIndexArray:[self.parent indexesForCell]];
    self.parent.colorLegend.maxOffsetsForLegend = [self.parent.inScopeImage maxOffsetsForIndexArray:[self.parent indexesForCell]];
    self.parent.colorLegend.minsForLegend = [self minsForLegend];
    self.parent.colorLegend.inflexionPointsForLegend = [self inflexionPointsForLegend];
    self.parent.colorLegend.colorsForLegend = self.parent.colorSpaceSelector.selectedSegment != 3?[self.parent.customChannelsDelegate collectColors]:nil;
    [self.parent.colorLegend setNeedsDisplay:YES];
}

-(void)refreshTiles{
    overrideRefresh = NO;
    
    if(self.parent.autoRefreshLock.state == NSOffState)
        return;
    
    dispatch_queue_t  threadPainting = dispatch_queue_create("aQ", NULL);
    dispatch_async(threadPainting, ^{
        NSMutableArray *images = @[].mutableCopy;
        NSMutableArray *involvedStacks = @[].mutableCopy;
        for (IMCComputationOnMask *comp in self.parent.inScopeComputations)
            if(![involvedStacks containsObject:comp.mask.imageStack])
                [involvedStacks addObject:comp.mask.imageStack];
        for (IMCPixelClassification *mask in self.parent.inScopeMasks)
            if(![involvedStacks containsObject:mask.imageStack])
                [involvedStacks addObject:mask.imageStack];
        for (IMCImageStack *stack in self.parent.inScopeImages)
            if(![involvedStacks containsObject:stack])
                [involvedStacks addObject:stack];
        
        [self scaleAndLegendChannelsTiles:involvedStacks];
        
        int cursor = 0;
        if(involvedStacks.count == 1){
            IMCImageStack *stack = (IMCImageStack *)involvedStacks.firstObject;
            NSMutableArray *ioi = self.parent.inOrderIndexes.copy;
            for (NSNumber * num in ioi) {
                
                if (overrideRefresh)
                    return;
                
                NSColor *col = [self.parent.customChannelsDelegate collectColors][cursor];//Is like case 4 later
                if(self.parent.colorSpaceSelector.selectedSegment == 0)col = [NSColor whiteColor];
                if(self.parent.colorSpaceSelector.selectedSegment == 1 || self.parent.colorSpaceSelector.selectedSegment == 2)
                    col = [NSColor colorInHueAtIndex:cursor totalColors:self.parent.inOrderIndexes.count withColoringType:self.parent.colorSpaceSelector.selectedSegment minumAmountColors:3];
                
                NSImage * image = [IMCImageGenerator
                                   imageForImageStacks:self.parent.inScopeComputations.count > 0?nil:self.parent.inScopeImages.copy
                                                                 indexes:@[num]
                                                        withColoringType:self.parent.colorSpaceSelector.selectedSegment !=3?4:3 customColors:@[col]
                                                       minNumberOfColors:3
                                                                   width:stack.width
                                                                  height:stack.height
                                                          withTransforms:NO
                                                                   blend:[IMCBlendModes blendModeForValue:self.parent.multiImageFilters.indexOfSelectedItem]
                                                                andMasks:self.parent.inScopeMasks
                                                         andComputations:self.parent.inScopeComputations
                                                              maskOption:self.parent.maskVisualizeSelector.selectedSegment
                                                                maskType:[self maskType]
                                                         maskSingleColor:self.parent.scaleBarColor.color
                                                         isAlignmentPair:NO
                                                             brightField:(BOOL)self.parent.brightFieldEffect.state];
                
                [images addObject:image];
                cursor++;
            }
            
        }
        else
        {
            NSMutableArray *arrayAll = @[].mutableCopy;
            for (IMCComputationOnMask *comp in self.parent.inScopeComputations)
                [arrayAll addObject:@{@"comp":comp}];
            for (IMCPixelClassification *mask in self.parent.inScopeMasks)
                [arrayAll addObject:@{@"mask":mask}];
            for (IMCImageStack *stack in self.parent.inScopeImages)
                [arrayAll addObject:@{@"stack":stack}];
            
            for (NSDictionary *dict in arrayAll) {
                
                if (overrideRefresh)
                    return;
                
                NSArray *keys = @[@"comp",@"mask",@"stack"];
                IMCImageStack *stck;
                id obj;
                int i = 0;
                while (!obj) {
                    obj = dict[keys[i]];
                    i++;
                }
                if([obj isMemberOfClass:[IMCImageStack class]])stck = obj;
                if([obj isMemberOfClass:[IMCPixelClassification class]])stck = [(IMCPixelClassification *)obj imageStack];
                if([obj isMemberOfClass:[IMCComputationOnMask class]])stck = [(IMCComputationOnMask *)obj mask].imageStack;
                if([obj isMemberOfClass:[IMCPixelMap class]])stck = [(IMCPixelMap *)obj imageStack];
                
                
                NSImage * image = [IMCImageGenerator imageForImageStacks:dict[@"stack"]?@[dict[@"stack"]].mutableCopy:nil
                                                                 indexes:self.parent.inOrderIndexes.copy
                                                        withColoringType:self.parent.colorSpaceSelector.selectedSegment !=3?4:3 customColors:[self.parent.customChannelsDelegate collectColors] minNumberOfColors:3 width:stck.width
                                                                  height:stck.height
                                                          withTransforms:NO
                                                                   blend:[IMCBlendModes blendModeForValue:self.parent.multiImageFilters.indexOfSelectedItem]
                                                                andMasks:dict[@"mask"]?@[dict[@"mask"]]:nil
                                                         andComputations:dict[@"comp"]?@[dict[@"comp"]]:nil
                                                              maskOption:self.parent.maskVisualizeSelector.selectedSegment
                                                                maskType:[self maskType]
                                                         maskSingleColor:self.parent.scaleBarColor.color
                                                         isAlignmentPair:NO
                                                             brightField:(BOOL)self.parent.brightFieldEffect.state];
                
                [images addObject:image];
            }
        }
        
        if(images.count > 0)
            dispatch_async(dispatch_get_main_queue(), ^{
                if (overrideRefresh)
                    return;
                [self.parent.scrollViewTiles assembleTiledWithImages:images];
            });
    });
}

-(void)refreshFromImageArray:(NSMutableArray *)array{
    if(array.count == 0)return;
    self.parent.scrollViewBlends.imageView.image = array.firstObject;
    [self.parent.scrollViewTiles assembleTiledWithImages:array];
}

-(void)scaleAndLegendChannelsBlend{
    if(self.parent.scaleBar.state == NSOnState)
        [self.parent.scrollViewBlends.imageView addScaleWithScaleFactor:self.parent.scaleBarCalibration.floatValue color:self.parent.scaleBarColor.color fontSize:self.parent.scaleBarFontSize.floatValue widthPhoto:self.parent.inScopeImage.width stepForced:self.parent.scaleBarSteps.integerValue onlyBorder:NO static:self.parent.scaleBarStatic.state];
    else [self.parent.scrollViewBlends.imageView removeScale];
    
    if(self.parent.legends.state == NSOnState)
        [self.parent.scrollViewBlends.imageView setLabels:[self.parent channelsForCell] withColors:[self.parent.customChannelsDelegate collectColors] backGround:[NSColor colorWithWhite:.1f alpha:.2f] fontSize:self.parent.legendsFontSize.floatValue vAlign:self.parent.legendsVertical.state static:self.parent.legendsStatic.state];
    else [self.parent.scrollViewBlends.imageView removeLabels];
}

-(void)scaleAndLegendChannelsTiles:(NSArray *)involvedStacks{
    
    self.parent.scrollViewTiles.scaleStep = self.parent.scaleBarSteps.integerValue;
    self.parent.scrollViewTiles.scaleFontSize = self.parent.scaleBarFontSize.floatValue;
    self.parent.scrollViewTiles.scaleCalibration = self.parent.scaleBarCalibration.floatValue;
    self.parent.scrollViewTiles.fontSizeLegends = self.parent.legendsFontSize.floatValue;
    
    self.parent.scrollViewTiles.showLegendChannels = self.parent.legends.state;
    self.parent.scrollViewTiles.showImageNames = self.parent.showNames.state;
    self.parent.scrollViewTiles.showScaleBars = self.parent.scaleBar.state;
    
    self.parent.scrollViewTiles.legendColor = self.parent.scaleBarColor.color;
        
    NSMutableArray *arr = @[].mutableCopy;
    NSMutableArray *cols = @[].mutableCopy;
    NSMutableArray *channs = @[].mutableCopy;
    
    for (IMCImageStack *stack in involvedStacks) {
        [arr addObject:stack.itemName.copy];
        if(involvedStacks.count > 1){
            [cols addObject:[self.parent.customChannelsDelegate collectColors].copy];
            [channs addObject:[self.parent channelsForCell].copy];
        }
        else
        {
            for (id color in [self.parent.customChannelsDelegate collectColors]) {
                [cols addObject:@[color]];
            }
            for (id chann in [self.parent channelsForCell]) {
                [channs addObject:@[chann]];
            }
        }
    }
    self.parent.scrollViewTiles.imageNames = arr;
    self.parent.scrollViewTiles.colorLegends = cols;
    self.parent.scrollViewTiles.channels = channs;
}

#pragma mark Color Legend

-(NSArray *)minsForLegend{NSMutableArray *arr = @[].mutableCopy; for(int i = 0; i < self.parent.inOrderIndexes.count; i++)[arr addObject:[NSNumber numberWithFloat:.0f]];return arr;}

-(NSArray *)inflexionPointsForLegend{
    NSMutableArray *arr = @[].mutableCopy;
    for(int i = 0; i < self.parent.inOrderIndexes.count; i++)
        [arr addObject:[NSNumber numberWithFloat:5.0f]];
    return arr;
}

#pragma mark Refresh R controls

-(void)refreshRControls{
    if(!self.parent.inScopeComputation)return;
    
    NSMutableArray *channsArr = @[@"CompId"].mutableCopy;
    for (IMCChannelWrapper *ch in [self.parent channelsInScopeForPlotting]) {
        [channsArr addObject:self.parent.inScopeComputation.channels[ch.index]];
    }
    NSArray *update = @[self.parent.xChannel, self.parent.yChannel, self.parent.cChannel, self.parent.sChannel, self.parent.f1Channel, self.parent.f2Channel];
    for(NSPopUpButton *pop in update)
        [General addArrayOfStrings:channsArr toNSPopupButton:pop noneAtBeggining:YES];
    
//    for(NSPopUpButton *pop in update){
//        NSInteger index = [update indexOfObject:pop]+2;
//        [pop selectItemAtIndex:index > channsArr.count?0:index];
//    }
}

#pragma mark control for toolpanels

-(void)checkToolsBlendMode{
    if(self.parent.applyTransfomrs.indexOfSelectedItem == 1){
        self.parent.scrollViewBlends.rotationDelegate = self.parent;
        if(self.parent.toolsContainer.superview)
            [self.parent.toolsContainer removeFromSuperview];
        if(!self.parent.alignmentToolsContainer.superview)
            [self.parent.blendToolsContainer addSubview:self.parent.alignmentToolsContainer];
    }else{
        self.parent.scrollViewBlends.rotationDelegate = nil;
        if(self.parent.alignmentToolsContainer.superview)
            [self.parent.alignmentToolsContainer removeFromSuperview];
        if(self.parent.toolsContainer.superview)
            [self.parent.toolsContainer removeFromSuperview];
        [self.parent.blendToolsContainer addSubview:self.parent.toolsContainer];
    }
    self.parent.applyTransfomrs.hidden = NO;
}

-(void)checkToolsTilesMode{
    if(!self.parent.toolsContainer.superview)[self.parent.toolsContainer removeFromSuperview];
    [self.parent.tilesToolsContainer addSubview:self.parent.toolsContainer];
    self.parent.scrollSubpanels.hidden = NO;
}

-(void)changedPanelScrollingType:(NSPopUpButton *)sender{
    self.parent.scrollViewTiles.scrollSubpanels = (sender.indexOfSelectedItem != 0);
    self.parent.scrollViewTiles.syncronised = (sender.indexOfSelectedItem > 1);
    if(sender == self.parent.applyTransfomrs){
        [self checkToolsBlendMode];
        [self refreshBlend];
    }
    if(sender == self.parent.scrollSubpanels)[self refreshTiles];
}

#pragma mark dimensions

-(void)updateForWithStack:(IMCImageStack *)stack{
    self.parent.sizeImage.stringValue = [NSString stringWithFormat:@"%li x %li pixels", stack.width, stack.height];
    self.parent.customChannelsDelegate.settingsJsonArray = stack.channelSettings;
    self.parent.transformDictController.transformDict = stack.transform;
}

#pragma mark align selected
-(void)alignPair:(NSArray<IMCNodeWrapper *>*)pair{
    if(pair.count != 2)
        return;
    BOOL wasLoadedFirst = pair.firstObject.isLoaded;
    BOOL wasLoadedSecond = pair.lastObject.isLoaded;
    
    if(!wasLoadedFirst)
        [pair.firstObject loadLayerDataWithBlock:nil];
    while (!pair.firstObject.isLoaded);
    
    if(!wasLoadedSecond)
        [pair.lastObject loadLayerDataWithBlock:nil];
    while (!pair.lastObject.isLoaded);
    
    NSInteger min = 0;
    if([pair.firstObject isMemberOfClass:[IMCImageStack class]])
        min = MAX(MAX(MAX([(IMCImageStack *)pair.firstObject width],
                          [(IMCImageStack *)pair.firstObject height]),
                      [(IMCImageStack *)pair.lastObject width]),
                  [(IMCImageStack *)pair.lastObject height]);
    if([pair.lastObject isMemberOfClass:[IMCComputationOnMask class]])
        min = MAX(MAX(MAX([[[(IMCComputationOnMask *)pair.firstObject mask]imageStack]width],
                          [[[(IMCComputationOnMask *)pair.firstObject mask]imageStack] height]),
                      [[[(IMCComputationOnMask *)pair.lastObject mask]imageStack] width]),
                  [[[(IMCComputationOnMask *)pair.lastObject mask]imageStack] height]);
    
    
    
    CGImageRef imageA = NULL;
    if([pair.firstObject isMemberOfClass:[IMCImageStack class]])
        imageA = [IMCImageGenerator whiteRotatedBufferForImage:(IMCImageStack *)pair.firstObject
                                                       atIndex:self.parent.channels.selectedRow
                                                  superCanvasW:min
                                                  superCanvasH:min];
    
    CGImageRef imageB = NULL;
    if([pair.lastObject isMemberOfClass:[IMCImageStack class]])
        imageB = [IMCImageGenerator whiteRotatedBufferForImage:(IMCImageStack *)pair.lastObject
                                                       atIndex:self.parent.channels.selectedRow
                                                  superCanvasW:min
                                                  superCanvasH:min];
    
    NSImage *im1;
    if(imageA)
        im1 = [[[NSImage alloc]initWithCGImage:imageA size:NSMakeSize(min, min)]gaussianBlurred:3];
    if([pair.firstObject isMemberOfClass:[IMCComputationOnMask class]])
        im1 = [IMCImageGenerator imageForImageStacks:nil
                                             indexes:@[@(self.parent.channels.selectedRow)]
                                    withColoringType:0
                                        customColors:@[[NSColor whiteColor]]
                                   minNumberOfColors:1
                                               width:min
                                              height:min
                                      withTransforms:YES
                                               blend:kCGBlendModeScreen
                                            andMasks:nil
                                     andComputations:@[(IMCComputationOnMask *)pair.firstObject]
                                          maskOption:self.parent.maskVisualizeSelector.selectedSegment
                                            maskType:[self maskType]
                                     maskSingleColor:self.parent.scaleBarColor.color
                                     isAlignmentPair:NO
                                         brightField:NO];
    
    NSImage *im2;
    if(imageB)
        im2 = [[[NSImage alloc]initWithCGImage:imageB size:NSMakeSize(min, min)]gaussianBlurred:3];
    if([pair.lastObject isMemberOfClass:[IMCComputationOnMask class]])
        im2 = [IMCImageGenerator imageForImageStacks:nil
                                             indexes:@[@(self.parent.channels.selectedRow)]
                                    withColoringType:0
                                        customColors:@[[NSColor whiteColor]]
                                   minNumberOfColors:1
                                               width:min
                                              height:min
                                      withTransforms:YES
                                               blend:kCGBlendModeScreen
                                            andMasks:nil
                                     andComputations:@[(IMCComputationOnMask *)pair.lastObject]
                                          maskOption:self.parent.maskVisualizeSelector.selectedSegment
                                            maskType:[self maskType]
                                     maskSingleColor:self.parent.scaleBarColor.color
                                     isAlignmentPair:NO
                                         brightField:NO];
    
    //[IMCRegistrationOCV alignTwoImages:im1 imageB:im2];
    
    static NSInteger multiplier = 1;
    NSInteger * i = &multiplier;
    
    NSMutableDictionary *trans;
    if([pair.lastObject isMemberOfClass:[IMCImageStack class]])
        trans = [(IMCImageStack *)pair.lastObject transform];
    if([pair.lastObject isMemberOfClass:[IMCComputationOnMask class]])
        trans = [[[(IMCComputationOnMask *)pair.lastObject mask]imageStack]transform];
    
    BOOL exact = NO;
    if([pair.firstObject isMemberOfClass:[IMCComputationOnMask class]] && [pair.lastObject isMemberOfClass:[IMCComputationOnMask class]])
        exact = YES;
    
    CGImageRef im = [IMCRegistration startRegistration:i
                                           sourceImage:im1.CGImage
                                           targetImage:im2.CGImage
                                            angleRange:0.5
                                             angleStep:0.001
                                              destDict:trans
                                        inelasticBrush:1
                                          elasticBrush:self.parent.elasticTransform.selectedSegment
                     exactMatches:exact];
    
    
    if(im)
        CFRelease(im);
    im = NULL;
    if(imageA)
        CFRelease(imageA);
    if(imageB)
        CFRelease(imageB);
    
    if(!wasLoadedFirst)
        [pair.firstObject unLoadLayerDataWithBlock:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshBlend];
    });
}
-(void)alignSelected{
        
    NSIndexSet *iSet = self.parent.filesTree.selectedRowIndexes;
    __block IMCNodeWrapper *firstStack = [self.parent.filesTree itemAtRow:iSet.firstIndex];
    if([firstStack isMemberOfClass:[IMCImageStack class]] || [firstStack isMemberOfClass:[IMCComputationOnMask class]])
        [iSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            IMCImageStack *stack = [self.parent.filesTree itemAtRow:index];
            if([stack isMemberOfClass:[IMCImageStack class]] || [firstStack isMemberOfClass:[IMCComputationOnMask class]])
                if(stack != firstStack){
                    [self alignPair:@[firstStack, stack]];
                    firstStack = stack;
                }
        }];
    if([firstStack isMemberOfClass:[IMCImageStack class]])
        self.parent.transformDictController.transformDict = [(IMCImageStack *)firstStack transform];
    if([firstStack isMemberOfClass:[IMCComputationOnMask class]])
        self.parent.transformDictController.transformDict = [[[(IMCComputationOnMask *)firstStack mask]imageStack] transform];
        
}


@end
