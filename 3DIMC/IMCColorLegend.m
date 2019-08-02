//
//  IMCColorLegend.m
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCColorLegend.h"

@implementation IMCColorLegend

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

void drawHeat(CGContextRef context, CGRect rect)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) [NSColor blueColor].CGColor,
                        (__bridge id) [NSColor cyanColor].CGColor,
                        (__bridge id) [NSColor cyanColor].CGColor,
                        (__bridge id) [NSColor greenColor].CGColor,
                        (__bridge id) [NSColor greenColor].CGColor,
                        (__bridge id) [NSColor yellowColor].CGColor,
                        (__bridge id) [NSColor yellowColor].CGColor,
                        (__bridge id)[NSColor redColor].CGColor
                        ];
    
    NSInteger inflexionPoints = 4;
    
    for (int i = 0; i < inflexionPoints; i++) {
        CGRect modRect = CGRectMake(rect.origin.x,
                                    rect.size.height/inflexionPoints * i,
                                    rect.size.width,
                                    rect.size.height/inflexionPoints);
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) [colors subarrayWithRange:NSMakeRange(i * 2, 2)], locations);
        
        CGPoint startPoint = CGPointMake(CGRectGetMidX(modRect), CGRectGetMinY(modRect));
        CGPoint endPoint = CGPointMake(CGRectGetMidX(modRect), CGRectGetMaxY(modRect));
        
        CGContextSaveGState(context);
        CGContextAddRect(context, modRect);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        CGContextRestoreGState(context);
        
        CGGradientRelease(gradient);
        
    }
    CGColorSpaceRelease(colorSpace);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    //BOOL isHeat = [self.delegate isHeatForLegend];
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    NSInteger count = self.maxsForLegend.count;
    
    if(self.minsForLegend.count == count && self.inflexionPointsForLegend.count == count){
        float upperLowerFreePortions = 0.035f;//5% up and down for min and max values
        float gapForNum = dirtyRect.size.height * upperLowerFreePortions;
        for (NSNumber *num in self.maxsForLegend) {
            NSInteger idx = [self.maxsForLegend indexOfObject:num];
            float y = (dirtyRect.size.height / count) * idx;
            
            CGRect rect = CGRectMake(0,
                                     y,
                                     dirtyRect.size.width,
                                     (dirtyRect.size.height / count) - gapForNum
                                     );
            
            NSColor * color = nil;
            if(self.colorsForLegend.count >= idx + 1)color = [self.colorsForLegend objectAtIndex:idx];
            NSColor *startColor = [NSColor blackColor];
            if(!color){
                //color = [NSColor redColor];
                //startColor = [NSColor blueColor];
            }
            
            if(!color)
                drawHeat(context, rect);
            else
                drawLinearGradient(context, rect, color.CGColor, startColor.CGColor);
            
            [General drawIntAsString:num.floatValue * [self.maxOffsetsForLegend[[self.maxsForLegend indexOfObject:num]]floatValue] WithFontName:@"Helvetica" size:10.0f rect:
             CGRectMake(0,
                        y + (dirtyRect.size.height / count) - gapForNum,
                        dirtyRect.size.width,
                        gapForNum * .75f)];
            
        }
    }
}

@end
