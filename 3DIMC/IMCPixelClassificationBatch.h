//
//  IMCCellSegmentationBatch.h
//  3DIMC
//
//  Created by Raul Catena on 3/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IMCPixelClassificationBatch <NSObject>

-(NSArray *)allStacks;
-(NSArray *)allTrainings;

@end

@interface IMCPixelClassificationBatch : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) id<IMCPixelClassificationBatch>delegate;
@property (nonatomic, weak) IBOutlet NSTableView *trainingsTableView;
@property (nonatomic, weak) IBOutlet NSTableView *stacksTableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

-(IBAction)startBatch:(NSButton *)sender;
-(IBAction)refreshTabless:(id)sender;

@end
