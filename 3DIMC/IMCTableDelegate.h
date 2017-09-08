//
//  IMCTableDelegate.h
//  3DIMC
//
//  Created by Raul Catena on 2/25/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;

@protocol TableDelegate <NSObject>

-(NSArray <IMCComputationOnMask *>*)computations;
-(NSTableView *)tableViewEvents;
-(NSTableView *)channels;

@end

@interface IMCTableDelegate : NSObject<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) id<TableDelegate>delegate;

-(void)rebuildTable;

@end
