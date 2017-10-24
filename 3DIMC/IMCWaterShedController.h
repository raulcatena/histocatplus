//
//  IMCWaterShedController.h
//  3DIMC
//
//  Created by Raul Catena on 10/23/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCTiledScrollView.h"

@interface IMCWaterShedController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet IMCTiledScrollView *scrollView;

@property (nonatomic, weak) IBOutlet NSPopUpButton *segmentationType;
@property (nonatomic, weak) IBOutlet NSPopUpButton *pixelMaps;
@property (nonatomic, weak) IBOutlet NSTextField *classLabel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *classFromMap;

@property (nonatomic, weak) IBOutlet NSSlider *max;
@property (nonatomic, weak) IBOutlet NSSlider *min;
@property (nonatomic, weak) IBOutlet NSSlider *mul;
@property (nonatomic, weak) IBOutlet NSSlider *spf;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *transform;

@end
