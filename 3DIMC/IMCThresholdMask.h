//
//  ThresholdMask.h
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCPixelClassification.h"
#import "IMCImageGenerator.h"
#import "IMCScrollView.h"
#import "NSView+Utilities.h"
#import "IMCMasks.h"
#import "IMCThresholder.h"


@class IMCImageStack;
@class IMCPixelClassification;

@interface IMCThresholdMask : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet NSTableView *tableViewChannels;
@property (nonatomic, weak) IBOutlet IMCScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSSlider *maxOffset;
@property (nonatomic, weak) IBOutlet NSSlider *minOffset;
@property (nonatomic, weak) IBOutlet NSSlider *multiplier;
@property (nonatomic, weak) IBOutlet NSSlider *spf;
@property (nonatomic, weak) IBOutlet NSTextField *threshold;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *transform;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *seeMask;
@property (nonatomic, weak) IBOutlet NSButton *flatten;
@property (nonatomic, weak) IBOutlet NSButton *saveInverse;
@property (nonatomic, weak) IBOutlet NSButton *showInverse;
@property (nonatomic, weak) IBOutlet NSTextField *label;

@property (nonatomic, strong) IMCThresholder *thresholder;

//Gaussian Blur
@property (nonatomic, weak) IBOutlet NSStepper *gaussianBlur;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *blur;
-(IBAction)changedBlur:(id)sender;
-(IBAction)changedLabel:(NSTextField *)sender;

-(instancetype)initWithStack:(IMCImageStack *)stack andMask:(IMCPixelClassification *)mask;
-(IBAction)generateBinaryMask:(id)sender;
-(IBAction)changedSettingChannel:(id)sender;
-(IBAction)refresh:(id)sender;
-(IBAction)saveMask:(id)sender;
-(void)initGUIRelatedOptions;
-(void)refreshProcessed:(BOOL)processed;

@end
