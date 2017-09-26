//
//  IMC3dMasking.h
//  3DIMC
//
//  Created by Raul Catena on 9/21/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCScrollView.h"
#import "IMCMtkView.h"

@protocol IMC3DMasker <NSObject>
-(NSArray *)masks;
@end

@interface IMC3dMasking : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet IMCScrollView *scrollLeft;
@property (nonatomic, weak) IBOutlet IMCMtkView *metalView;
@property (nonatomic, weak) id<IMC3DMasker>delegate;
@end
