//
//  IMCCompensation.h
//  3DIMC
//
//  Created by Raul Catena on 9/10/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCLoader;

@interface IMCCompensation : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, weak) IBOutlet NSTableView *tableView;

-(instancetype)initWithDataCoordinator:(IMCLoader *)coordinator;
-(IBAction)saveMatrix:(id)sender;
-(IBAction)revertFactory:(id)sender;
@end
