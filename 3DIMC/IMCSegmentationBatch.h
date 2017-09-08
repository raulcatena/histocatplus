//
//  IMCSegmentationBatch.h
//  3DIMC
//
//  Created by Raul Catena on 3/6/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IMCCellSegmenationBatch <NSObject>

-(NSArray *)allMapsForSegmentation;

@end

@interface IMCSegmentationBatch : NSWindowController
@property (nonatomic, weak) id<IMCCellSegmenationBatch>delegate;

@property (nonatomic, weak) IBOutlet NSTableView *mapsTableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

@property (nonatomic, weak) IBOutlet NSTextField *minCellDiam;
@property (nonatomic, weak) IBOutlet NSTextField *maxCellDiam;
@property (nonatomic, weak) IBOutlet NSTextField *lowerThreshold;
@property (nonatomic, weak) IBOutlet NSTextField *upperThreshold;

-(IBAction)startBatch:(NSButton *)sender;
-(IBAction)refreshTabless:(id)sender;

@end
