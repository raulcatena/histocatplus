//
//  IMCWorkspaceSelector.h
//  3DIMC
//
//  Created by Raul Catena on 2/17/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCWorkSpace;

@interface IMCWorkspaceSelector : NSObject<NSOutlineViewDelegate, NSOutlineViewDataSource, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IMCWorkSpace * parent;

-(IBAction)updateTableView:(NSSegmentedControl *)sender;
-(NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows;

@end
