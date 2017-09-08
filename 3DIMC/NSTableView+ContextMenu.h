//
//  NSTableView+ContextMenu.h
//  IMCReader
//
//  Created by Raul Catena on 10/11/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ContextMenuDelegate <NSObject>
- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows;
@end

@interface NSTableView (ContextMenu)

@end
