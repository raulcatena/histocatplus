//
//  IMCPositions.h
//  3DIMC
//
//  Created by Raul Catena on 11/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OpenGLView.h"

@class IMCLoader;
@class IMCMtkView;
@class IMCTiledScrollView;

@interface IMCPositions : NSWindowController<NSTableViewDelegate, NSTableViewDataSource, Get3DData>

@property (nonatomic, weak) IBOutlet NSPopUpButton * positionsSelector;
@property (nonatomic, weak) id<Get3DData>delegate;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;

-(instancetype)initWithLoader:(IMCLoader *)loader andView:(IMCMtkView *)view andSV:(IMCTiledScrollView *)scrollView;

-(IBAction)addProfile:(id)sender;
-(IBAction)removeProfile:(id)sender;
-(IBAction)setPositionProfile:(id)sender;
-(IBAction)refreshList:(id)sender;

@end
