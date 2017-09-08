//
//  IMCScale.m
//  IMCReader
//
//  Created by Raul Catena on 5/20/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCScale.h"

@interface IMCScale(){
    CGFloat scaleFactor;
    CGFloat widthPhoto;
    CGFloat xorig;
    CGFloat fontSize;
    NSInteger step;
    BOOL _onlyBorder;
}
@property (nonatomic, strong) NSColor *color;
@end

@implementation IMCScale

-(id)initWithFrame:(NSRect)frameRect andScaleFactor:(CGFloat)factor andColor:(NSColor *)color widthPhoto:(NSInteger)pixelsWide atXOrigin:(CGFloat)xorigin fontSize:(CGFloat)afontSize stepForced:(NSInteger)stepForced onlyBorder:(BOOL)onlyBorder{
    self = [self initWithFrame:frameRect];
    if (self) {
        scaleFactor = factor;
        self.color = color;
        widthPhoto = pixelsWide;
        xorig = xorigin;
        fontSize = afontSize;
        step = stepForced;
        _onlyBorder = onlyBorder;
    }
    return self;
}

-(void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
    
    CGContextRef ctx= [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetLineWidth(ctx,fontSize/10.0f);
    CGFloat components[4];
    if(self.color){
        [self.color getComponents:components];
    }
    CGContextSetRGBStrokeColor(ctx,components[0], components[1], components[2], components[3]);
    
    float firstOrder = widthPhoto/10.0f;
    
    NSInteger cursor = 1.0f;
    while (cursor < firstOrder) {
        cursor *= 4;
    }
    
    if(step > 0){
        firstOrder =
        cursor = 50 * step;
    }
    
    float cornerMargin = self.bounds.size.width/15;
    cursor /= scaleFactor;
    
    float realWidth = self.frame.size.width;
    if (xorig > 0) {
        realWidth = self.frame.size.width - 2 * xorig;
    }
    
    float proportion = realWidth/widthPhoto;
    float barWidthInView = (float)cursor * proportion;
    CGContextMoveToPoint(ctx, cornerMargin + xorig, cornerMargin);
    CGContextAddLineToPoint(ctx, cornerMargin + xorig  + barWidthInView, cornerMargin);
    CGContextStrokePath(ctx);
    
    if(_onlyBorder == YES)return;
    
    NSString *leg = [NSString stringWithFormat:@"%li µm", (long)cursor];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:fontSize];
    
    CGFloat x = xorig + cornerMargin + cornerMargin/2.0f;
    CGFloat y = cornerMargin + cornerMargin/2.0f;
    
    CGSize size = [leg sizeWithAttributes:@{
                                            NSForegroundColorAttributeName: self.color,
                                            NSFontAttributeName: font}];
    
    [leg drawInRect:NSMakeRect(x,
                               y,
                               size.width,
                               size.height) withAttributes:@{
                                                       NSForegroundColorAttributeName: self.color,
                                                       NSFontAttributeName: font}];
}

@end
