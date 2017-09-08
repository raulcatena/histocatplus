//
//  IMCThresholdBatch.h
//  3DIMC
//
//  Created by Raul Catena on 3/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IMCThresholdBatch <NSObject>

-(NSArray *)allStacks;
-(NSArray *)allThresholdPixClassifications;

@end

@interface IMCThresholdBatch : NSWindowController

@property (nonatomic, weak) id<IMCThresholdBatch>delegate;
@property (nonatomic, weak) IBOutlet NSTableView *thresholdedTableView;
@property (nonatomic, weak) IBOutlet NSTableView *stacksTableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

-(IBAction)startBatch:(NSButton *)sender;
-(IBAction)refreshTabless:(id)sender;

@end
