//
//  IMCPixelClassification.m
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelClassificationTool.h"
#import "NSView+Utilities.h"
#import "IMCRandomForests.h"
#import "IMCBlendModes.h"
#import "NSColor+Utilities.h"
#import "IMCPixelMap.h"
#import "NSImage+OpenCV.h"
#import "IMCFileExporter.h"

@interface IMCPixelClassificationTool (){

}

@end

@implementation IMCPixelClassificationTool


-(instancetype)initWithStack:(IMCImageStack *)stack andTraining:(IMCPixelTraining *)training{
    self = [self initWithWindowNibName:NSStringFromClass([IMCPixelClassificationTool class])];
    if(self){
        if(!training){
            training = [[IMCPixelTraining alloc]init];
            training.parent = stack;//Important to set this before loading buffer
            [training loadBuffer];
        }
        self.trainer = [[IMCPixelTrainer alloc]initWithStack:stack andTrainings:@[training]];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.brushTools = (IMCBrushTools *)[NSView loadWithNibNamed: NSStringFromClass([IMCBrushTools class]) owner:nil class:[IMCBrushTools class]];
    [self.brushToolsContainer addSubview:self.brushTools];
    
    self.scrollView.imageView.imageAlignment = NSImageAlignTopLeft;
    self.scrollView.delegate = self;
    
    [self.channelTableView setDoubleAction:@selector(doubleClickOnRow:)];
    [self.multiImageFilters addItemsWithTitles:[IMCBlendModes blendModes]];
    if(VIEWER_ONLY)
        self.multiImageFilters.hidden = YES;
    [self.multiImageFilters selectItem:[self.multiImageFilters itemAtIndex:3]];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}

#pragma mark outline view

#pragma mark Outline View DataSource


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(IMCButtonLayer *)item{
    return [self.trainer.useChannels containsObject:item]?YES:NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(IMCButtonLayer *)item{
    if(!item)
        return self.trainer.options.count;
    return item.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(IMCButtonLayer *)item{
    if(item == nil)
        return self.trainer.options[index];
    
    return item.children[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(IMCButtonLayer *)item{
    
    if(!item.parent)
        return item.channel;
    return [item nameForOption];
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
        IMCButtonLayer *lay = [self.channelTableView itemAtRow:self.channelTableView.selectedRow];
        [self.trainer toogleOption:lay];
    }
    [self.channelTableView reloadData];
}

-(NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows{
    NSMenu *menu = [[NSMenu alloc]initWithTitle:@""];
    if(aTableView == self.channelTableView){
        IMCButtonLayer *lay = [self.channelTableView itemAtRow:self.channelTableView.selectedRow];
        if(!lay.parent){
            for (NSInteger i = 1; i < 30; i++) {
                for (IMCButtonLayer *child in lay.children)
                    if(child.type == i)
                        continue;
                
                NSString *title = @"Raw Pixel Data";
                if (i > PIXEL_LAYER_DIRECT && i < PIXEL_LAYER_LOG_3) {
                    title = [NSString stringWithFormat:@"Gaussian Blur %lix%li", 1 + 2*(i - 1), 1 + 2*(i - 1)];
                }
                if (i > PIXEL_LAYER_GB_51 && i < PIXEL_LAYER_CANNY_3) {
                    title = [NSString stringWithFormat:@"Laplacian of Gaussian %lix%li", 1 + 2*(i - 8), 1 + 2*(i - 8)];
                }
                if (i > PIXEL_LAYER_LOG_51 && i < PIXEL_LAYER_GAUSSIAN_GRAD_3) {
                    title = [NSString stringWithFormat:@"Canny ED %lix%li", 1 + 2*(i - 15), 1 + 2*(i - 15)];
                }
                if (i > PIXEL_LAYER_CANNY_51) {
                    title = [NSString stringWithFormat:@"Gaussian Gradient %lix%li", 1 + 2*(i - 22), 1 + 2*(i - 22)];
                }
                
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title
                                                                  action:@selector(addType:) keyEquivalent:@""];
                menuItem.tag = i;
                [menu addItem:menuItem];
            }
        }else{
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:@"Remove"
                                                              action:@selector(removeNode:) keyEquivalent:@""];
            menuItem.tag = [lay.parent.children indexOfObject:lay];
            [menu addItem:menuItem];
        }
    }
    return menu;
}
-(void)addType:(NSMenuItem *)sender{
    IMCButtonLayer *lay = [self.channelTableView itemAtRow:self.channelTableView.selectedRow];
    if(!lay.parent){
        IMCButtonLayer *child = [[IMCButtonLayer alloc]init];
        child.type = (PixelLayerType)sender.tag;
        child.parent = lay;
    }
    [self.channelTableView reloadData];
}
-(void)removeNode:(NSMenuItem *)sender{
    IMCButtonLayer *lay = [self.channelTableView itemAtRow:self.channelTableView.selectedRow];
    lay.parent = nil;
    [self.channelTableView reloadData];
}

#pragma mark tableview

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return tableView == self.channelTableView?self.trainer.stack.channels.count:self.trainer.labels.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    return self.trainer.labels[row];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    if(!self.inOrderIndexes)self.inOrderIndexes = @[].mutableCopy;
    [General orderIndexesUponSelection:self.inOrderIndexes indexes:self.channelTableView.selectedRowIndexes];
    [self refresh];
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if([self.trainer.useChannels containsObject:[NSNumber numberWithInteger:row]])
        [(NSTextFieldCell *)cell setTextColor:[NSColor colorWithRed:0 green:0.5 blue:0 alpha:1.0f]];
    else
        [(NSTextFieldCell *)cell setTextColor:[NSColor blackColor]];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return (tableView == self.labelsTableView);
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if (tableView == self.labelsTableView){
        [self.trainer.labels replaceObjectAtIndex:row withObject:object];
        [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
    }
}

#pragma mark label handling

-(IBAction)addLabel:(id)sender{
    if(!self.trainer.labels)self.trainer.labels = @[].mutableCopy;
    [self.trainer.labels addObject:@"New label"];
    [self.labelsTableView reloadData];
    [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
}
-(IBAction)removeLabel:(id)sender{
    if(self.labelsTableView.selectedRow >= 0)
        [self.trainer.labels removeObjectAtIndex:[self.labelsTableView selectedRow]];
    [self.labelsTableView reloadData];
    [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
}

#pragma mark Machine Learning


-(void)calculateMaps:(id)sender{    
    [self.trainer classifyPixelsAllSteps];
    [self refresh];
}

#pragma mark refresh

-(void)refresh:(id)sender{
    [self refresh];
}

-(NSMutableArray *)imageRefsForIndexSet:(NSIndexSet *)indexSet{
    NSMutableArray *refs = @[].mutableCopy;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        IMCButtonLayer *lay = [self.channelTableView itemAtRow:self.channelTableView.selectedRow];
        NSImage *image = [self.trainer imageForNode:lay inStack:self.trainer.stack];
        [refs addObject:(__bridge id)image.CGImage];
    }];
    return refs;
}

-(void)refresh{
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:self.channelTableView.selectedRowIndexes.count];
    for (int i = 0; i < self.channelTableView.selectedRowIndexes.count; i++) {
        [colors addObject:[NSColor whiteColor]];
    }
    
    NSMutableArray *refs = @[].mutableCopy;
    
    
    if(self.showTraining.state == NSControlStateValueOn){
        UInt8 *remapped = [IMCImageGenerator mapMaskTo255:self.trainer.trainingNodes.firstObject.trainingBuffer length:self.trainer.stack.numberOfPixels toMax:4.0f];
        CGImageRef training = [IMCImageGenerator imageFromCArrayOfValues:remapped
                                                                   color:nil
                                                                   width:self.trainer.stack.width
                                                                  height:self.trainer.stack.height
                                                        startingHueScale:255/3 * 2
                                                            hueAmplitude:255/3 * 2
                                                               direction:YES
                                                              ecuatorial:NO
                                                            brightField:NO];
        
        const CGFloat myMaskingColors[6] = { 0, 100, 0, 100, 0, 100 };
        CGImageRef masked = CGImageCreateWithMaskingColors (training, myMaskingColors);
        
        if(masked)
            [refs addObject:(__bridge id)masked];
        if(training)
            CFRelease(training);
    
        free(remapped);
    }
    
    if(self.showPMap.state == NSControlStateValueOn){
        CGImageRef refi = [self.trainer.mapPrediction pMap];
        if(refi)
            [refs addObject:(__bridge id)refi];
    }
    
    
    
    if(self.showImage.state == NSControlStateValueOn){
        [refs addObjectsFromArray:[self imageRefsForIndexSet:self.channelTableView.selectedRowIndexes]];
    }
    
    NSImage *final = [IMCImageGenerator imageWithArrayOfCGImages:refs width:self.trainer.stack.width height:self.trainer.stack.height blendMode:[IMCBlendModes blendModeForValue:self.multiImageFilters.indexOfSelectedItem]];
    
    self.scrollView.imageView.image = final;
}

-(IBAction)changedTolerance:(NSSlider *)sender{
    
}

-(IBAction)eraseCurrentMask:(id)sender{
    if(self.trainer.trainingNodes.firstObject.trainingBuffer == NULL)return;
    NSInteger pixels = self.trainer.stack.numberOfPixels;
    for (NSInteger i = 0; i <pixels; i++)
        if(self.trainer.trainingNodes.firstObject.trainingBuffer[i] == self.labelsTableView.selectedRow + 1)
            self.trainer.trainingNodes.firstObject.trainingBuffer[i] = 0;
    [self refresh];
}
-(UInt8 *)maskInScope{
    return NULL;
}
-(void)fillBufferMask:(UInt8 *)paintMask fromDataBuffer:(UInt8 *)buffer withPoint:(NSPoint)trans width:(NSInteger)width height:(NSInteger)height{
    
}

#pragma mark mask painting

-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll{
    
    if(self.labelsTableView.selectedRow < 0)return;
    
    NSPoint event_location = [event locationInWindow];
    NSPoint processed = [self.scrollView.imageView convertPoint:event_location fromView:nil];
    processed = [self.scrollView getTranslatedPoint:processed];
    NSInteger pix = MAX(0, MIN(self.trainer.stack.numberOfPixels - 1, floor(processed.y) * self.trainer.stack.width + processed.x));
    
    if(self.brushTools.brushType < IMC_BRUSH_BUCKET)
    
        [self.brushTools paintOrRemove:self.brushTools.brushType == IMC_BRUSH_BRUSH?NO:YES mask:self.trainer.trainingNodes.firstObject.trainingBuffer index:pix fillInteger:self.labelsTableView.selectedRow + 1 imageWidth:self.trainer.stack.width imageHeight:self.trainer.stack.height];
    
//    if(self.brushTools.brushType == IMC_BRUSH_BUCKET)
//        
//        [self.brushTools fillBufferMask:self.trainingBuffer fromDataBuffer:[IMCImageGenerator bufferForImageRef:<#(CGImageRef)#>] index:<#(NSInteger)#> width:<#(NSInteger)#> height:<#(NSInteger)#> fill:<#(NSInteger)#>];
    
    //self.trainingBuffer[pix] = self.labelsTableView.selectedRow + 1;
    [self refresh];
}

#pragma mark save stuff


-(BOOL)isSegmentation{
    return [self isMemberOfClass:NSClassFromString(@"IMCCellSegmentation")];
}

-(void)saveTraining:(NSButton *)sender{
    [self.trainer saveTrainingSettingsSegmentation:self.trainer.trainingNodes.firstObject];
    [self.trainer saveTrainingMask:self.trainer.trainingNodes.firstObject];
}
-(void)savePredictionMap:(NSButton *)sender{
    [self.trainer.mapPrediction savePixelMapPredictions];
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
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    //NSInteger changeCount = [pasteBoard clearContents];
    NSString *string = [General jsonStringFromObject:@[[self.trainer.trainingNodes.firstObject learningSettings], self.trainer.labels] prettryPrint:NO];
    [pasteBoard setString:string forType:NSPasteboardTypeString];
}
-(IBAction)pasteTrainingSettings:(NSButton *)sender{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *got = [pasteboard stringForType:NSPasteboardTypeString];
    NSArray *options = [General objectFromString:got];
    IMCPixelTraining *training = self.trainer.trainingNodes[0];
    if(training){
        training.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS] = options.firstObject;
        training.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LABELS] = options.lastObject;
    }
        
    [self.trainer updateTrainingSettings];
    [self.channelTableView reloadData];
    [self.labelsTableView reloadData];
    
}

@end
