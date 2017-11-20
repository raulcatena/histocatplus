//
//  IMCGeneralPlot.m
//  IMCReader
//
//  Created by Raul Catena on 9/13/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCGeneralPlot.h"

@interface IMCGeneralPlot()

@end

@implementation IMCGeneralPlot

-(float)cornerMargin{
    if(_cornerMargin == 0.0f)_cornerMargin = 40.0f;
    return _cornerMargin;
}

-(float)thicknessAxes{
    if(_thicknessAxes == 0.0f)_thicknessAxes = 1.0f;
    return _thicknessAxes;
}

-(float)axesPointSize{
    if(_axesPointSize == 0.0f)_axesPointSize = 22.0f;
    return _axesPointSize;
}

-(float)transparencyPoints{
    if(_transparencyPoints == 0.0f)_transparencyPoints = .3f;
    return _transparencyPoints;
}

-(float)sizePoints{
    if(_sizePoints == 0.0f)_sizePoints = 1.0f;
    return _sizePoints;
}

-(float)proportionX{
    if(_proportionX == 0.0f)_proportionX = 1.0f;
    return _proportionX;
}

-(float)proportionY{
    if(_proportionY == 0.0f)_proportionY = 1.0f;
    return _proportionY;
}

-(NSColor *)axesColor{
    if(!_axesColor) _axesColor = [NSColor blackColor];
    return _axesColor;
}

-(NSColor *)pointsColor{
    if(!_pointsColor)_pointsColor = [NSColor blueColor];
    return _pointsColor;

}

-(NSColor *)backGroundCol{
    if(!_backGroundCol)_backGroundCol = [NSColor whiteColor];
    return _backGroundCol;
    
}

-(void)drawLabels:(CGContextRef)ctx{
    
    if(!self.titlesX)return;
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:self.axesPointSize];
    for (NSString *title in self.titlesX.copy) {
        NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
        [style setAlignment:NSCenterTextAlignment];
        
        
        NSDictionary *attrs = @{
                                NSForegroundColorAttributeName: self.axesColor,
                                NSFontAttributeName: font,
                                NSParagraphStyleAttributeName: style
                                };
        
        
        
//        attrs = @{
//                  NSForegroundColorAttributeName: self.axesColor,
//                  NSFontAttributeName: font,
//                  NSParagraphStyleAttributeName: style
//                  };
        
        if(title)[title drawInRect:NSMakeRect(
                                    self.cornerMargin,
                                    0,
                                    self.bounds.size.width - 2 * self.cornerMargin,
                                    self.cornerMargin)
          withAttributes:attrs];
        
      
    }
    CGContextConcatCTM(ctx, CGAffineTransformMakeRotation(M_PI/2));
    
    if(!self.titlesXY)return;
    for (NSString *title in self.titlesXY.copy) {
        
        NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
        [style setAlignment:NSCenterTextAlignment];
        
        
        NSDictionary *attrs = @{
                                NSForegroundColorAttributeName: self.axesColor,
                                NSFontAttributeName: font,
                                NSParagraphStyleAttributeName: style
                                };
        
        
        
        attrs = @{
                  NSForegroundColorAttributeName: self.axesColor,
                  NSFontAttributeName: font,
                  NSParagraphStyleAttributeName: style
                  };
        
        if(title)[title drawInRect:NSMakeRect(
                                     self.cornerMargin,
                                     -self.cornerMargin,
                                     self.bounds.size.height - 2 * self.cornerMargin,
                                     self.cornerMargin)
           withAttributes:attrs];
        
        
    }
    CGContextConcatCTM(ctx, CGAffineTransformMakeRotation(-M_PI/2));
}

-(void)maxLabels:(CGContextRef)ref{
    
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:12.0f];
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    NSDictionary *attrs = @{
                            NSForegroundColorAttributeName: self.axesColor,
                            NSFontAttributeName: font,
                            NSParagraphStyleAttributeName: style
                            };


    if(self.maxX != 0.0f)[[NSString stringWithFormat:@"%.0f", self.maxX] drawInRect:CGRectMake(self.bounds.size.width - 100, 0, 100, self.cornerMargin) withAttributes:attrs];
    if(self.maxY != 0.0f)[[NSString stringWithFormat:@"%.0f", self.maxY] drawInRect:CGRectMake(0, self.bounds.size.height - 50, self.cornerMargin, self.cornerMargin) withAttributes:attrs];
}

-(void)drawAxes:(CGContextRef)ctx{
    
    CGContextSetLineWidth(ctx,self.thicknessAxes);
    if(!self.colorSpace)self.colorSpace = [NSColorSpace sRGBColorSpace];
    NSColor *color = [self.axesColor colorUsingColorSpace:self.colorSpace];
    CGContextSetRGBStrokeColor(ctx,color.redComponent,color.greenComponent,color.blueComponent,1.0f);
    
    CGContextMoveToPoint(ctx, self.cornerMargin, self.cornerMargin);
    CGContextAddLineToPoint(ctx, self.cornerMargin, self.cornerMargin + self.bounds.size.height - self.cornerMargin);
    CGContextStrokePath(ctx);
    CGContextMoveToPoint(ctx, self.cornerMargin, self.cornerMargin);
    CGContextAddLineToPoint(ctx, self.cornerMargin + self.bounds.size.width - self.cornerMargin - _widthLegend, self.cornerMargin);
    CGContextStrokePath(ctx);
}

-(void)drawPoints:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect{
    //Always override without calling super
}

-(void)setBackGroundColor:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect{
    if(!self.colorSpace)self.colorSpace = [NSColorSpace sRGBColorSpace];
    NSColor *col = [self.backGroundCol colorUsingColorSpace:self.colorSpace];
    CGContextSetRGBFillColor(ctx, col.redComponent, col.greenComponent, col.blueComponent, col.alphaComponent);
    CGContextFillRect(ctx, NSRectToCGRect(dirtyRect));
}

-(void)addTopLabel:(NSString *)topTitle context:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect{
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:self.axesPointSize];
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    NSDictionary *attrs = @{
                            NSForegroundColorAttributeName: self.axesColor,
                            NSFontAttributeName: font,
                            NSParagraphStyleAttributeName: style
                            };
    
    
    [topTitle drawInRect:CGRectMake(0, dirtyRect.size.height - 40, dirtyRect.size.width, 40) withAttributes:attrs];
    
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
}

@end
