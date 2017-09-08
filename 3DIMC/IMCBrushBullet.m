//
//  IMCBrushBullet.m
//  3DIMC
//
//  Created by Raul Catena on 2/14/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCBrushBullet.h"

@implementation IMCBrushBullet

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    CGContextRef ctx= [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetRGBStrokeColor(ctx,.0f,.0f,.0f,0.7);
    CGContextSetLineWidth(ctx, 30.0f);
    
    CGContextAddArc(ctx,
                    self.bounds.size.width/2,
                    self.bounds.size.height/2,
                    (float)self.sizeBrush,
                    0.0f,
                    M_PI*2,
                    YES);
    CGContextStrokePath(ctx);
}

@end
