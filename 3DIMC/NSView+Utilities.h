//
//  NSView+NSView_Utilities.h
//  IMCReader
//
//  Created by Raul Catena on 9/20/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (Utilities)

-(NSImage *)getImageBitMapFromRect:(CGRect)rect;
-(NSImage *)getImageBitMapFull;
+ (NSView *)loadWithNibNamed:(NSString *)nibNamed owner:(id)owner class:(Class)loadClass ;
- (UInt8 *)bufferForView ;

@end
