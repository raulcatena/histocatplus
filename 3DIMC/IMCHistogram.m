//
//  IMCHistogram.m
//  histoCAT Viewer
//
//  Created by Raul Catena on 3/29/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import "IMCHistogram.h"

@interface IMCHistogram(){
    int **counts;
    NSInteger channs;
}

@property (nonatomic) NSArray *colors;

@end

@implementation IMCHistogram

-(void)releaseData{
    if(counts){
        for(NSInteger i = 0; i < channs; i++)
            free(counts[i]);
        free(counts);
        channs = 0;
    }
}
-(void)primeWithData:(UInt8 **)data channels:(NSInteger)channels pixels:(NSInteger)pixels colors:(NSArray *)colors{
    if(self.bitsAmplitude != 8 && self.bitsAmplitude != 16)
        self.bitsAmplitude = 8;
    [self releaseData];
    self.colors =  colors;
    channs = channels;
    counts = calloc(channs, sizeof(int *));
    for(NSInteger i = 0; i < channs; i++){
        counts[i] = calloc(256, sizeof(int));
        for(NSInteger j = 0; j < pixels; j++)
            counts[i][data[i][j]]++;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if(counts){
        NSColor *col = [[NSColor blackColor]colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        CGContextRef ctx= [[NSGraphicsContext currentContext] CGContext];
        CGContextSetLineWidth(ctx, 2);
        float margin = dirtyRect.size.width * 0.2f;
        float width = dirtyRect.size.width - 2 * margin;
        float heigth = dirtyRect.size.height - 2 * margin;
        for(int i = 0; i < channs; i++){
            if(self.colors && self.colors.count > i)
                col = [self.colors[i] colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
            CGContextSetRGBStrokeColor(ctx, col.redComponent,
                                       col.greenComponent,
                                       col.blueComponent,
                                       1.0);
            CGContextMoveToPoint(ctx, margin, margin);
            
            int max = 0;
            for(int bin = 1; bin < 256; bin++)
                if(counts[i][bin] > max)
                    max = counts[i][bin];
            float xFactor = width/256;
            float yFactor = heigth/max;
            for(int bin = 1; bin < 256; bin++){
                CGContextMoveToPoint(ctx, margin + (bin - 1) * xFactor, margin + counts[i][bin - 1] * yFactor);
                CGContextAddLineToPoint(ctx, margin + bin * xFactor, margin + counts[i][bin] * yFactor);
                CGContextStrokePath(ctx);
            }
        }
    }
}

-(void)dealloc{
    [self releaseData];
}

@end
