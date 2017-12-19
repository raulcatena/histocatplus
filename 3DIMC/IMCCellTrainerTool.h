//
//  IMCCellTrainerTool.h
//  3DIMC
//
//  Created by Raul Catena on 3/10/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCCellTrainer.h"
#import "IMCTiledScrollView.h"

@class IMCComputationOnMask;
@class IMCMaskTraining;

@interface IMCCellTrainerTool : NSWindowController<NSTableViewDelegate, NSTableViewDataSource, IMCScrollViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource>{
}

@property (nonatomic, strong) IMCCellTrainer *trainer;

@property (nonatomic, strong) NSMutableArray *inOrderIndexes;
@property (nonatomic, strong) NSArray *settingsImages;

@property (nonatomic, assign) IBOutlet NSOutlineView *channelTableView;
@property (nonatomic, assign) IBOutlet NSTableView *labelsTableView;

@property (nonatomic, weak) IBOutlet IMCTiledScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *multiImageFilters;

@property (nonatomic, weak) IBOutlet NSButton *showImage;
@property (nonatomic, weak) IBOutlet NSButton *showPMap;
@property (nonatomic, weak) IBOutlet NSButton *showPMapUncertainty;
@property (nonatomic, weak) IBOutlet NSButton *showTraining;
@property (nonatomic, weak) IBOutlet NSButton *showClassification;
@property (nonatomic, weak) IBOutlet NSButton *showPixelData;
@property (nonatomic, weak) IBOutlet NSButton *showMaskBorder;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *pixelsColoring;

//Initializer
-(instancetype)initWithComputation:(IMCComputationOnMask *)computation andTraining:(IMCMaskTraining *)training;

//Refresh
-(IBAction)refresh:(id)sender;
-(void)refresh;

//Labels
-(IBAction)addLabel:(id)sender;
-(IBAction)removeLabel:(id)sender;

//Calculate maps and buffer handling
-(IBAction)calculateMaps:(id)sender;
-(IBAction)eraseCurrentMask:(id)sender;
-(IBAction)changedTolerance:(NSSlider *)sender;


-(UInt8 *)maskInScope;
-(void)fillBufferMask:(UInt8 *)paintMask fromDataBuffer:(UInt8 *)buffer withPoint:(NSPoint)trans width:(NSInteger)width height:(NSInteger)height;

//Save stuff
//-(IBAction)saveTraining:(NSButton *)sender;
-(IBAction)savePredictions:(NSButton *)sender;
-(int *)trainingBuff;

-(IBAction)copyTrainingSettings:(NSButton *)sender;
-(IBAction)pasteTrainingSettings:(NSButton *)sender;

@end
