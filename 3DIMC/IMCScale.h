//
//  IMCScale.h
//  IMCReader
//
//  Created by Raul Catena on 5/20/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCScale : NSView
-(id)initWithFrame:(NSRect)frameRect andScaleFactor:(CGFloat)factor andColor:(NSColor *)color widthPhoto:(NSInteger)pixelsWide atXOrigin:(CGFloat)xorigin fontSize:(CGFloat)afontSize stepForced:(NSInteger)stepForced onlyBorder:(BOOL)onlyBorder;
@end
