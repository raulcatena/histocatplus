//
//  IMCPixelClassification.h
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCBrushTools.h"
#import "IMCTiledScrollView.h"
#import "IMCImageStack.h"
#import "IMCButtonLayer.h"
#import "IMCImageGenerator.h"
#import "IMCPixelTraining.h"
#import "IMCPixelTrainer.h"

@class IMCImageStack;

@interface IMCPixelClassificationTool : NSWindowController<NSTableViewDelegate, NSTableViewDataSource, IMCScrollViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource>{
}

@property (nonatomic, strong) IMCPixelTrainer *trainer;

@property (nonatomic, strong) NSMutableArray *inOrderIndexes;
@property (nonatomic, strong) NSArray *settingsImages;

@property (nonatomic, assign) IBOutlet NSOutlineView *channelTableView;
@property (nonatomic, assign) IBOutlet NSTableView *labelsTableView;

@property (nonatomic, weak) IMCBrushTools *brushTools;
@property (nonatomic, weak) IBOutlet NSView *brushToolsContainer;
@property (nonatomic, weak) IBOutlet IMCTiledScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *multiImageFilters;

@property (nonatomic, weak) IBOutlet NSButton *showImage;
@property (nonatomic, weak) IBOutlet NSButton *showPMap;
@property (nonatomic, weak) IBOutlet NSButton *showPMapUncertainty;
@property (nonatomic, weak) IBOutlet NSButton *showTraining;
@property (nonatomic, weak) IBOutlet NSButton *showClassification;




//Initializer
-(instancetype)initWithStack:(IMCImageStack *)stack andTraining:(IMCPixelTraining *)training;

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
-(IBAction)saveTraining:(NSButton *)sender;
-(IBAction)savePredictionMap:(NSButton *)sender;

-(IBAction)copyTrainingSettings:(NSButton *)sender;
-(IBAction)pasteTrainingSettings:(NSButton *)sender;

@end
