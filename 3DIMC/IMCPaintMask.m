//
//  IMCPaintMask.m
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPaintMask.h"
#import "IMCMasks.h"

@interface IMCPaintMask ()

@end

@implementation IMCPaintMask


- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.brushTools = (IMCBrushTools *)[NSView loadWithNibNamed: NSStringFromClass([IMCBrushTools class]) owner:nil class:[IMCBrushTools class]];
    [self.brushToolsContainer addSubview:self.brushTools];
    
    self.scrollView.imageView.imageAlignment = NSImageAlignTopLeft;
    self.scrollView.delegate = self;
}

#pragma mark mask painting

-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll{
    if(!self.thresholder.paintMask)
        self.thresholder.paintMask = calloc(self.thresholder.stack.numberOfPixels, sizeof(int));
    
    NSPoint event_location = [event locationInWindow];
    NSPoint processed = [self.scrollView.imageView convertPoint:event_location fromView:nil];
    processed = [self.scrollView getTranslatedPoint:processed];
    NSInteger pix = MAX(0, MIN(self.thresholder.stack.numberOfPixels - 1, floor(processed.y) * self.thresholder.stack.width + processed.x));
    
    if(self.brushTools.brushType < IMC_BRUSH_BUCKET)
        
        [self.brushTools paintOrRemove:self.brushTools.brushType == IMC_BRUSH_BRUSH?NO:YES mask32Bit:self.thresholder.paintMask index:pix fillInteger:1 imageWidth:self.thresholder.stack.width imageHeight:self.thresholder.stack.height];
    
    [self refreshProcessed:NO];
}

@end
