//
//  IMCPositions.h
//  3DIMC
//
//  Created by Raul Catena on 11/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCLoader;
@class IMCMtkView;

@interface IMCPositions : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

-(instancetype)initWithLoader:(IMCLoader *)loader andView:(IMCMtkView *)view;

@end
