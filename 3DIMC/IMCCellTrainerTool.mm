//
//  IMCCellTrainerTool.m
//  3DIMC
//
//  Created by Raul Catena on 3/10/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellTrainerTool.h"
#import "IMCComputationOnMask.h"
#import "IMCMaskTraining.h"
#import "IMCCellTrainer.h"
#import "IMCImageGenerator.h"
#import "IMCPixelClassification.h"
#import "NSImage+OpenCV.h"
#import "IMCBlendModes.h"
#import "IMCFileExporter.h"

@interface IMCCellTrainerTool ()

@end

@implementation IMCCellTrainerTool

-(instancetype)initWithComputation:(IMCComputationOnMask *)computation andTraining:(IMCMaskTraining *)training{
    self = [self initWithWindowNibName:NSStringFromClass([self class])];
    if(self){
        if(!training){
            training = [[IMCMaskTraining alloc]init];
            training.itemName = @"New Cell Training";
            training.parent = computation;//Important to set this before loading buffer
            [training loadBuffer];
        }
        self.trainer = [[IMCCellTrainer alloc]initWithComputation:computation andTrainings:@[training]];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//TODO
        [[NSApplication sharedApplication] runModalForWindow:self.window];
    });
    
    self.scrollView.imageView.imageAlignment = NSImageAlignTopLeft;
    self.scrollView.delegate = self;
    
    [self.channelTableView setDoubleAction:@selector(doubleClickOnRow:)];
    [self.multiImageFilters addItemsWithTitles:[IMCBlendModes blendModes]];
    if(VIEWER_ONLY)
        self.multiImageFilters.hidden = YES;
    [self.multiImageFilters selectItem:[self.multiImageFilters itemAtIndex:2]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}

#pragma mark outline view

#pragma mark Outline View DataSource


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    NSInteger inte = [self.trainer.computation.channels indexOfObject:item];
    return [[self.trainer.trainingNodes.firstObject useChannels]containsObject:@(inte)];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if(!item)
        return self.trainer.computation.channels.count;
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    if(item == nil)
        return self.trainer.computation.channels[index];
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item{
    return item;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification{
    [self refresh];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    return NO;
}

-(void)doubleClickOnRow:(NSOutlineView *)aTableView{
    if (aTableView == self.channelTableView) {
        [self.trainer toogleChannel:self.channelTableView.selectedRow];
    }
    [self.channelTableView reloadData];
}

#pragma mark tableview

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.trainer.labels.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    if(row == self.labelsTableView.selectedRow)
        return [@"->" stringByAppendingString:self.trainer.labels[row]];
    return self.trainer.labels[row];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if(!self.inOrderIndexes)self.inOrderIndexes = @[].mutableCopy;
    [General orderIndexesUponSelection:self.inOrderIndexes indexes:self.channelTableView.selectedRowIndexes];
    [self refresh];
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if(tableView == self.channelTableView)
        if([self.trainer.useChannels containsObject:[NSNumber numberWithInteger:row]])
            [(NSTextFieldCell *)cell setTextColor:[NSColor colorWithRed:0 green:0.5 blue:0 alpha:1.0f]];
        else
            [(NSTextFieldCell *)cell setTextColor:[NSColor blackColor]];
        else{
            float sector = 1.0f/self.trainer.labels.count;
            float hue = .0f + sector * (row + 1);
            [(NSTextFieldCell *)cell setTextColor:[NSColor colorWithHue:hue saturation:1.0f brightness:1.0f alpha:1.0f]];
        }
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return (tableView == self.labelsTableView);
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if (tableView == self.labelsTableView){
        object = [object stringByReplacingOccurrencesOfString:@"->" withString:@""];
        [self.trainer.labels replaceObjectAtIndex:row withObject:object];
        //[self.trainer saveTraining];
    }
}

#pragma mark label handling

-(IBAction)addLabel:(id)sender{
    
    [self.trainer.labels addObject:@"New label"];
    [self.labelsTableView reloadData];
    //[self.trainer saveTraining];
    [self refresh];
}
-(IBAction)removeLabel:(id)sender{
    if(self.labelsTableView.selectedRow >= 0)
        [self.trainer.labels removeObjectAtIndex:[self.labelsTableView selectedRow]];
    NSInteger segments = [self.trainer numberOfSegments];
    for (NSInteger i = 0; i < segments; i++) {
        if([self trainingBuff][i] == self.labelsTableView.selectedRow + 1)
            [self trainingBuff][i] = 0;
        if([self trainingBuff][i] > self.labelsTableView.selectedRow + 1)
            [self trainingBuff][i]--;
    }
    [self.labelsTableView reloadData];
    //[self.trainer saveTraining];
    [self refresh];
}

#pragma mark Machine Learning


-(void)calculateMaps:(id)sender{
    [self.trainer classifyCellsAllSteps];
    [self refresh];
}

#pragma mark refresh

-(void)refresh:(id)sender{
    [self refresh];
}
-(UInt8 *)createImageForTrainingWithmaskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    
    NSInteger size = self.trainer.computation.mask.imageStack.numberOfPixels;
    int * copy = (int *)calloc(size, sizeof(int));
    for (NSInteger i = 0; i < size; i++) {
        copy[i] = self.trainer.computation.mask.mask[i];
    }
    
    UInt8 * img = (UInt8 *)calloc(size, sizeof(UInt8));
    if(img == NULL || self.trainer.trainingNodes.firstObject.training == NULL)
        return NULL;
    
    int * cellData = self.trainer.trainingNodes.firstObject.training;
    float factor = 255.0f/self.trainer.labels.count;
    
    for (NSInteger i = 0; i < size; i++) {
        if(copy[i] == 0)continue;
        NSInteger index = abs(copy[i]) - 1;
        int val = cellData[index] * (int)factor;
        if(maskType == MASK_ALL_CELL)
            img[i] = val;
        else{
            if(maskType == MASK_CYT)
                img[i] = MAX((copy[i] > 0) * val, 0);
            if(maskType == MASK_NUC)
                img[i] = MAX((copy[i] < 0) * val, 0);
            if(maskType == MASK_NUC_PLUS_CYT)
                if(copy[i] !=0)
                    img[i] = (copy[i]/abs(copy[i])) * val;
        }
    }
    
    free(copy);
    return img;
}
-(UInt8 *)createImageForClassificationWithmaskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    
    if(!self.trainer.randomFResults)
        return NULL;
    
    NSInteger size = self.trainer.computation.mask.imageStack.numberOfPixels;
    int * copy = (int *)calloc(size, sizeof(int));
    
    for (NSInteger i = 0; i < size; i++)
        copy[i] = self.trainer.computation.mask.mask[i];
    
    UInt8 * img = (UInt8 *)calloc(size, sizeof(UInt8));
    if(img == NULL || self.trainer.trainingNodes.firstObject.training == NULL)
        return NULL;
    
    float * learntData = self.trainer.randomFResults;
    float factor = 255.0f/self.trainer.labels.count;
    
    for (NSInteger i = 0; i < size; i++) {
        if(copy[i] == 0)continue;
        NSInteger index = abs(copy[i]) - 1;
        float orValue = learntData[index * (self.trainer.useChannels.count + 1) + self.trainer.useChannels.count];
        int classPredicted = floor(orValue);
        //float prob = orValue - classPredicted;
        int val = classPredicted * (int)factor;
        if(maskType == MASK_ALL_CELL)
            img[i] = val;
        else{
            if(maskType == MASK_CYT)
                img[i] = MAX((copy[i] > 0) * val, 0);
            if(maskType == MASK_NUC)
                img[i] = MAX((copy[i] < 0) * val, 0);
            if(maskType == MASK_NUC_PLUS_CYT)
                if(copy[i] !=0)
                    img[i] = (copy[i]/abs(copy[i])) * val;
        }
    }
    free(copy);
    return img;
}
-(void)addUint8Buffer:(UInt8 *)buffer toStack:(NSMutableArray *)stackRefs direction:(BOOL)clockWise{

    CGImageRef refi = [IMCImageGenerator imageFromCArrayOfValues:buffer color:nil width:self.trainer.computation.mask.imageStack.width height:self.trainer.computation.mask.imageStack.height startingHueScale:0 hueAmplitude:255 direction:clockWise ecuatorial:NO brightField:NO];
    
    const CGFloat myMaskingColors[6] = { 0, 100, 0, 100, 0, 100 };
    CGImageRef masked = CGImageCreateWithMaskingColors (refi, myMaskingColors);
    
    if(masked)
        [stackRefs addObject:(__bridge id)masked];
    if(refi)
        CFRelease(refi);
    
    if(buffer)
        free(buffer);
}
-(void)refresh{
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:self.channelTableView.selectedRowIndexes.count];
    
    for (int i = 0; i < self.channelTableView.selectedRowIndexes.count; i++)
        [colors addObject:[NSColor whiteColor]];
    
    NSMutableArray *refs = @[].mutableCopy;    
    
    if(self.showTraining.state == NSOnState){
        UInt8 * tempMask = [self createImageForTrainingWithmaskOption:MASK_NO_BORDERS maskType:MASK_ALL_CELL maskSingleColor:nil];
        [self addUint8Buffer:tempMask toStack:refs direction:YES];
    }
    
    if(self.showPMap.state == NSOnState){
        UInt8 * tempMask = [self createImageForClassificationWithmaskOption:MASK_NO_BORDERS maskType:MASK_ALL_CELL maskSingleColor:nil];
        [self addUint8Buffer:tempMask toStack:refs direction:YES];
    }
    
    if(self.showImage.state == NSOnState && self.channelTableView.selectedRow != NSNotFound){
        //TODO enable pixel data here
        CGImageRef ref = NULL;
        if(self.showPixelData.state == NSOffState)
            ref = [self.trainer.computation coloredMaskForChannel:self.channelTableView.selectedRow color:[NSColor whiteColor] maskOption:MASK_FULL maskType:MASK_ALL_CELL maskSingleColor:[NSColor whiteColor] brightField:NO];
        if(self.showPixelData.state == NSOnState){
            IMCImageStack *stack = self.trainer.computation.mask.imageStack;
            NSMutableArray *foundChannels = @[].mutableCopy;
            NSMutableArray *colors = @[].mutableCopy;
            [self.channelTableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                NSInteger foundPixChannel = [stack ascertainIndexInStackForComputationChannel:self.trainer.computation.originalChannels[idx]];
                if(foundPixChannel == NSNotFound)
                    foundPixChannel = [stack ascertainIndexInStackForComputationChannel:self.trainer.computation.channels[idx]];
                if(foundPixChannel != NSNotFound){
                    [foundChannels addObject:@(foundPixChannel)];
                    [colors addObject:[NSColor whiteColor]];
                }
                
            }];
            
            if(!stack.isLoaded)
                [stack loadLayerDataWithBlock:nil];
            while(!stack.isLoaded);

            ref = [[IMCImageGenerator imageForImageStacks:@[stack].mutableCopy
                                                  indexes:foundChannels
                                         withColoringType:0
                                             customColors:self.pixelsColoring.selectedSegment == 0?colors:nil
                                        minNumberOfColors:3
                                                    width:stack.width
                                                   height:stack.height
                                           withTransforms:NO
                                                    blend:kCGBlendModeScreen
                                                 andMasks:self.showMaskBorder.state == NSOnState?@[self.trainer.computation.mask]:nil
                                          andComputations:nil
                                               maskOption:MASK_ONE_COLOR_BORDER
                                                 maskType:MASK_ALL_CELL
                                          maskSingleColor:[NSColor whiteColor]
                                          isAlignmentPair:NO
                                              brightField:NO]CGImage];
        }
        
//        NSImage *image = [IMCImageGenerator imageForImageStacks:nil indexes:self.inOrderIndexes withColoringType:0 customColors:nil minNumberOfColors:3 width:self.trainer.computation.mask.imageStack.width height:self.trainer.computation.mask.imageStack.height withTransforms:NO blend:kCGBlendModeScreen andMasks:nil andComputations:@[self.trainer.computation] maskOption:0 maskType:MASK_ALL_CELL maskSingleColor:nil isAlignmentPair:NO brightField:NO];
        if(ref)
            [refs addObject:(__bridge id)ref];
    }
    if(refs.count > 0)
        self.scrollView.imageView.image = [IMCImageGenerator imageWithArrayOfCGImages:refs width:self.trainer.computation.mask.imageStack.width height:self.trainer.computation.mask.imageStack.height blendMode:kCGBlendModeOverlay];
}

-(IBAction)changedTolerance:(NSSlider *)sender{
    
}

-(IBAction)eraseCurrentMask:(id)sender{
    NSInteger segments = [self.trainer numberOfSegments];
    for(NSInteger o = 0; o < segments; o++)
        if([self trainingBuff][o] == self.labelsTableView.selectedRow + 1)
            [self trainingBuff][o] = 0;
    [self.trainer.trainingNodes.firstObject regenerateDictTraining];
    [self refresh];
}
-(UInt8 *)maskInScope{
    return NULL;
}
-(void)fillBufferMask:(UInt8 *)paintMask fromDataBuffer:(UInt8 *)buffer withPoint:(NSPoint)trans width:(NSInteger)width height:(NSInteger)height{
    
}
-(int *)trainingBuff{
    return self.trainer.trainingNodes.firstObject.training;
}

#pragma mark mask painting
-(void)clickedAtPoint:(NSPoint)point{
    NSPoint processed = [self.scrollView getTranslatedPoint:point];
    NSInteger pix = MAX(0, MIN(self.trainer.computation.mask.imageStack.numberOfPixels - 1, floor(processed.y) * self.trainer.computation.mask.imageStack.width + processed.x));
    
    int cellId = abs(self.trainer.computation.mask.mask[pix]);
    if(cellId > 0 && self.labelsTableView.selectedRow >= 0)
        [self trainingBuff][cellId - 1] = [self trainingBuff][cellId - 1] == 0?(int)self.labelsTableView.selectedRow + 1:0;
    
    [self.trainer.trainingNodes.firstObject regenerateDictTraining];
    [self refresh];
}
//-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll{
//    
//    if(self.labelsTableView.selectedRow < 0)return;
//    
//    NSPoint event_location = [event locationInWindow];
//    NSPoint processed = [self.scrollView.imageView convertPoint:event_location fromView:nil];
//    processed = [self.scrollView getTranslatedPoint:processed];
//    NSInteger pix = MAX(0, MIN(self.trainer.computation.mask.imageStack.numberOfPixels - 1, floor(processed.y) * self.trainer.computation.mask.imageStack.width + processed.x));
//    
//    int cellId = self.trainer.computation.mask.mask[pix];
//    if(cellId > 0){
//    
//    }
//    [self refresh];
//}

#pragma mark save stuff


//-(void)saveTraining:(NSButton *)sender{
//    [self.trainer saveTraining];
//}
-(void)savePredictions:(NSButton *)sender{
    [self.trainer addResultsToComputation];
}

#pragma mark copy

-(IBAction)copy:(id)sender{
    [IMCFileExporter copyToClipBoardFromScroll:self.scrollView allOrZoomed:NO];
}
-(IBAction)copyCurrentVisible:(NSButton *)sender{
    [IMCFileExporter copyToClipBoardFromScroll:self.scrollView allOrZoomed:YES];
}

-(IBAction)copyTrainingSettings:(id)sender{
    NSPasteboard * pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    //NSInteger changeCount = [pasteBoard clearContents];
    NSString *string = [General jsonStringFromObject:@[[self.trainer.trainingNodes.firstObject useChannels], self.trainer.labels] prettryPrint:NO];
    [pasteBoard setString:string forType:NSStringPboardType];
}
-(IBAction)pasteTrainingSettings:(NSButton *)sender{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *got = [pasteboard stringForType:NSStringPboardType];
    NSArray *options = [General objectFromString:got];
    IMCMaskTraining *training = self.trainer.trainingNodes[0];
    if(training){
        training.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS] = options.firstObject;
        training.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LABELS] = options.lastObject;
    }
    
    [self.trainer updateTrainingSettings];
    [self.channelTableView reloadData];
    [self.labelsTableView reloadData];
    
}

@end
