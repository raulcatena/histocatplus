//
//  IMCCellClassificationBatch.h
//  3DIMC
//
//  Created by Raul Catena on 3/13/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol IMCCellClassificationBatch <NSObject>

-(NSArray *)allComputations;
-(NSArray *)allCellTrainings;

@end

@interface IMCCellClassificationBatch : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) id<IMCCellClassificationBatch>delegate;
@property (nonatomic, weak) IBOutlet NSTableView *trainingsTableView;
@property (nonatomic, weak) IBOutlet NSTableView *computationsTableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

-(IBAction)startBatch:(NSButton *)sender;
-(IBAction)refreshTabless:(id)sender;

@end
