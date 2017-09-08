//
//  IMCMiniRConsole.h
//  3DIMC
//
//  Created by Raul Catena on 3/15/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCMiniRConsole : NSWindowController<NSTextViewDelegate>
@property (nonatomic, strong) IBOutlet NSTextView *rScript;
@end
