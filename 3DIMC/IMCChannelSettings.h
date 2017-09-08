//
//  IMCChannelSettings.h
//  IMCReader
//
//  Created by Raul Catena on 1/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCChannelSettings;
@protocol ChannelConfCell <NSObject>

-(void)madeChannelConfChanges;
-(NSInteger)numberOfChannels;
-(NSInteger)typeOfColoring;

@end

@interface IMCChannelSettings : NSTableCellView

@property (nonatomic, weak) IBOutlet NSTextField * label;
@property (nonatomic, weak) IBOutlet NSSlider *maxOffset;
@property (nonatomic, weak) IBOutlet NSSlider *offset;
@property (nonatomic, weak) IBOutlet NSSlider *multiplier;
@property (nonatomic, weak) IBOutlet NSSlider *pixelFilter;
@property (nonatomic, weak) IBOutlet NSPopUpButton *filter;
@property (nonatomic, weak) IBOutlet NSPopUpButton *selectChannel;
@property (nonatomic, weak) IBOutlet NSColorWell *color;
@property (nonatomic, weak) IBOutlet NSButton *showOrNot;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *transformData;
@property (nonatomic, weak) IBOutlet NSView *background;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger localIndex;

@property (nonatomic, strong) NSMutableDictionary *settingsDictionary;

@property (nonatomic, weak) NSArray *channels;

@property (nonatomic, assign) id<ChannelConfCell>delegate;

-(IBAction)selectedChannel:(id)sender;
-(void)setTag:(NSInteger)atag;

@end
