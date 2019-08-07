//
//  ThresholdMask.m
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCThresholdMask.h"
#import "NSImage+OpenCV.h"

@interface IMCThresholdMask (){
    
}
@property (nonatomic, strong) NSMutableArray *settingsDictionary;
@property (nonatomic, strong) NSMutableArray *inOrderIndexes;
@end

@implementation IMCThresholdMask

-(instancetype)initWithStack:(IMCImageStack *)stack andMask:(IMCPixelClassification *)mask{
    self = [self initWithWindowNibName:NSStringFromClass([self class])];
    if(self){
        self.thresholder = [[IMCThresholder alloc]init];
        self.thresholder.stack = stack;
        self.thresholder.mask = mask;
        self.thresholder.isPaint = !([[self className] isEqualToString:NSStringFromClass([IMCThresholdMask class])]);
        self.settingsDictionary = self.thresholder.stack.channelSettings;
    }
    return self;
}

-(void)initGUIRelatedOptions{
    if(self.thresholder.mask){
        
        [self.tableViewChannels selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.thresholder.mask.thresholdSettings[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_CHANNEL]integerValue]] byExtendingSelection:NO];
        
        self.threshold.integerValue = [self.thresholder.mask.thresholdSettings[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_THRESHOLD]integerValue];
        self.flatten.state = [self.thresholder.mask.thresholdSettings[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FLATTEN]boolValue];
        self.gaussianBlur.integerValue = [self.thresholder.mask.thresholdSettings[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_GAUSSIAN]integerValue];
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self initGUIRelatedOptions];
    [self.tableViewChannels setDoubleAction:@selector(doubleClickTable:)];
    
}
- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return  self.thresholder.stack.channels.count;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return self.thresholder.stack.channels[row];
}
-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if(self.thresholder.framerIndex == row)
        [(NSTextFieldCell *)cell setTextColor:[NSColor colorWithRed:0 green:1 blue:0 alpha:1.0f]];
    else
        [(NSTextFieldCell *)cell setTextColor:[NSColor blackColor]];
}
-(void)doubleClickTable:(NSTableView *)table{
    self.thresholder.framerIndex = [table selectedRow] == self.thresholder.framerIndex? -1 : [table selectedRow];
    [self.tableViewChannels reloadData];
}
-(void)updateSliders{
    NSMutableDictionary *settingsChannel = self.settingsDictionary[self.tableViewChannels.selectedRow];
    
    self.maxOffset.floatValue = [settingsChannel[JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET]floatValue];
    self.minOffset.floatValue = [settingsChannel[JSON_DICT_CHANNEL_SETTINGS_OFFSET]floatValue];
    self.multiplier.floatValue = [settingsChannel[JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER]floatValue];
    self.spf.floatValue = [settingsChannel[JSON_DICT_CHANNEL_SETTINGS_SPF]floatValue];
    [self.transform setSelectedSegment:MAX(0,MIN(2,[settingsChannel[JSON_DICT_CHANNEL_SETTINGS_TRANSFORM]integerValue]))];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    [self updateSliders];
    [self refreshProcessed:YES];
}

-(void)changedSettingChannel:(id)sender{
    NSMutableDictionary *settingsChannel = self.settingsDictionary[self.tableViewChannels.selectedRow];
    
    [settingsChannel setValue:[NSNumber numberWithFloat:self.maxOffset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET];
    [settingsChannel setValue:[NSNumber numberWithFloat:self.minOffset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_OFFSET];
    [settingsChannel setValue:[NSNumber numberWithFloat:self.multiplier.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER];
    [settingsChannel setValue:[NSNumber numberWithFloat:self.spf.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_SPF];
    [settingsChannel setValue:[NSNumber numberWithInteger:self.transform.selectedSegment] forKey:JSON_DICT_CHANNEL_SETTINGS_TRANSFORM];
    
    [self refreshProcessed:YES];
}
-(void)changedBlur:(id)sender{
    [self.blur setLabel:[NSString stringWithFormat:@"%li x %li", self.gaussianBlur.integerValue, self.gaussianBlur.integerValue] forSegment:1];
    self.thresholder.blur = self.gaussianBlur.integerValue;
    [self refreshProcessed:YES];
}
-(void)changedLabel:(NSTextField *)sender{
    self.thresholder.label = sender.stringValue;
}
-(void)refresh:(id)sender{
    if(self.tableViewChannels.selectedRow == NSNotFound)
        return;
    [self refreshProcessed:YES];
}
-(void)generateBinaryMask:(id)sender{
    if(self.tableViewChannels.selectedRow == NSNotFound)
        return;
    
    [self passValsToThresholder];
    [self.thresholder generateBinaryMask];
    
    if (self.thresholder.paintMask != NULL) {
        self.seeMask.hidden = NO;
        self.flatten.hidden = NO;
        self.saveInverse.hidden = NO;
        [self refreshProcessed:YES];
    }
}

-(void)passValsToThresholder{
    self.thresholder.channelIndex = self.tableViewChannels.selectedRow;
    self.thresholder.flatten = (BOOL)self.flatten.state;
    self.thresholder.saveInverse = (BOOL)self.saveInverse.state;
    self.thresholder.thresholdValue = self.threshold.integerValue;
    self.thresholder.blur = self.blur.selectedSegment == 0?1:self.gaussianBlur.integerValue;
}

-(void)refreshProcessed:(BOOL)processed{
    [self passValsToThresholder];
    
    NSMutableArray *arr = @[].mutableCopy;
    if(self.seeMask.selectedSegment != 1){
        CGImageRef image = [self.thresholder channelImage];
        [arr addObject:(__bridge id)image];
    }
    
    if(self.seeMask.selectedSegment > 0 && self.thresholder.paintMask)
    {
        
        int * mask;
        if(self.showInverse.state == NSControlStateValueOn)
            mask = [IMCMasks invertMaskCopy:self.thresholder.paintMask size:self.thresholder.stack.numberOfPixels];
        else
            mask = processed?[self.thresholder processedMask]:self.thresholder.paintMask;
        
        CGImageRef maskImage = [IMCImageGenerator colorMask:mask numberOfColors:20 singleColor:nil width:self.thresholder.stack.width height:self.thresholder.stack.height];
        [arr addObject:(__bridge id)maskImage];
        if((mask && processed) || self.showInverse.state == NSControlStateValueOn)
            free(mask);
    }
    self.scrollView.imageView.image = [IMCImageGenerator imageWithArrayOfCGImages:arr width:self.thresholder.stack.width height:self.thresholder.stack.height blendMode:kCGBlendModeScreen];
}

-(void)saveMask:(id)sender{
    if(self.showInverse.state == NSControlStateValueOn){
        int * mask = mask = [IMCMasks invertMaskCopy:self.thresholder.paintMask size:self.thresholder.stack.numberOfPixels];
        int * retainMask = self.thresholder.paintMask;
        self.thresholder.paintMask = mask;
        [self.thresholder saveMask];
        self.thresholder.paintMask = retainMask;
        if(mask)
            free(mask);
    }
    else
        [self.thresholder saveMask];
    
}


@end
