//
//  IMCCombineMasks.h
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCScrollView.h"

@protocol MaskCombiner <NSObject>

-(NSArray *)allStacks;

@end

@interface IMCCombineMasks : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IBOutlet NSTableView *stacksTableView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *originMask;
@property (nonatomic, weak) IBOutlet NSPopUpButton *targetMask;
@property (nonatomic, weak) IBOutlet NSPopUpButton *calculation;

@property (nonatomic, weak) IBOutlet NSSegmentedControl *whichLabels;
-(IBAction)changedWhichLabels:(NSSegmentedControl *)sender;
@property (nonatomic, weak) IBOutlet NSTextField *specificlabel;
-(IBAction)chosenLabel:(NSTextField *)sender;

@property (nonatomic, weak) IBOutlet IMCScrollView *originScroll;
@property (nonatomic, weak) IBOutlet IMCScrollView *targetScroll;
@property (nonatomic, weak) IBOutlet IMCScrollView *outputScroll;

@property (nonatomic, weak) IBOutlet NSSlider *tolerance;
@property (nonatomic, weak) IBOutlet NSTextField *toleranceLabel;
@property (nonatomic, weak) IBOutlet NSButton *captureId;

@property (nonatomic, weak) IBOutlet NSSlider *certaintySlider;
@property (nonatomic, weak) IBOutlet NSTextField *certaintyField;

//@property (nonatomic, weak) IBOutlet NSPopUpButton *saveResult;
@property (nonatomic, weak) id<MaskCombiner>delegate;
-(IBAction)refresh:(id)sender;
-(IBAction)addResults:(id)sender;

@end
