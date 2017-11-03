//
//  IMCScrollView.m
//  3DIMC
//
//  Created by Raul Catena on 1/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCScrollView.h"
#import <CoreImage/CoreImage.h>

@interface IMCScrollView(){
    float zoomFactor;
    NSPoint position;
    
    NSInteger histogramType;
}

@property (nonatomic, strong) NSImage *reserveImage;

@end

@implementation IMCScrollView

#pragma mark start

-(instancetype)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if(self){
        [self startImageView];
    }
    return self;
}

-(void)startImageView{
    IMCImageView *iv = [[IMCImageView alloc]initWithFrame:NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height)];
    iv.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
    self.imageView = iv;
    [self.imageView setImageScaling:NSImageScaleProportionallyUpOrDown];
    [self setDocumentView:self.imageView];
    self.takingEvents = YES;
    
//    self.hasVerticalRuler = YES;
//    self.hasHorizontalRuler = YES;
//    self.rulersVisible = YES;
}

-(void)awakeFromNib{
    [self startImageView];
}

#pragma mark click management

-(BOOL)acceptsFirstResponder{
    return self.takingEvents;
}

#pragma mark size calculations

-(NSPoint)getTranslatedPoint:(NSPoint)point{
    float propX = self.imageView.image.size.width/self.imageView.bounds.size.width;
    float propY = self.imageView.image.size.height/self.imageView.bounds.size.height;
    
    float prop = MAX(propX, propY);
    
    return NSMakePoint(point.x * prop,
                       (self.imageView.bounds.size.height - point.y) * prop
                       );
}

//-(void)mouseMoved:(NSEvent *)theEvent{
//
//}

#pragma mark mouse events

-(void)magnifyWithEvent:(NSEvent *)event{
    [super magnifyWithEvent:event];
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(scrolledWithScroll:)])
            [self.delegate scrolledWithScroll:self];
}

-(void)scrollWheel:(NSEvent *)theEvent{
    if([theEvent modifierFlags] & NSEventModifierFlagCommand){
        NSPoint endInWindow = [theEvent locationInWindow];
        NSPoint center = [self convertPoint:endInWindow fromView:nil];
        zoomFactor += theEvent.deltaY *0.05;
        if(zoomFactor > self.maxMagnification)zoomFactor = self.maxMagnification;
        if(zoomFactor < self.minMagnification)zoomFactor = self.minMagnification;
        position.x += theEvent.deltaX;
        [self setMagnification:zoomFactor centeredAtPoint:NSMakePoint(center.x + position.x, self.bounds.size.height - center.y)];
    }
    else
    {
        [super scrollWheel:theEvent];
    }
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(scrolledWithScroll:)])
            [self.delegate scrolledWithScroll:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    if([self.delegate respondsToSelector:@selector(mouseUpCallback:)])
        [self.delegate draggedThrough:theEvent scroll:self];
    
    if([theEvent clickCount] == 2)
    {
        [self toggleHistogram];
    }
}

-(void)mouseDown:(NSEvent *)theEvent{
    NSPoint event_location = [theEvent locationInWindow];
    //Important to pass nil
    //Call method over the scrolled document view
    NSPoint processed = [self.imageView convertPoint:event_location fromView:nil];
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(clickedAtPoint:)])
            [self.delegate clickedAtPoint:processed];
}


-(void)scrollWithEvent:(NSEvent *)theEvent{
    NSPoint pos = self.contentView.documentVisibleRect.origin;
    pos.x -= theEvent.deltaX;
    pos.y += theEvent.deltaY;
    [self.contentView scrollToPoint:pos];
}

-(void)mouseDragged:(NSEvent *)theEvent{
    if([theEvent modifierFlags] & NSEventModifierFlagOption){
        if(self.rotationDelegate){
            [self.rotationDelegate rotated:-theEvent.deltaY];
            return;
        }
        [self scrollWithEvent:theEvent];
    }else{
        [super mouseDragged:theEvent];
        [self.rotationDelegate translated:theEvent];
    }
    
    if([self.delegate respondsToSelector:@selector(draggedThrough:scroll:)])
            [self.delegate draggedThrough:theEvent scroll:self];
        
}

#pragma mark rotate gesture

-(void)rotateWithEvent:(NSEvent *)event{
    [self.rotationDelegate rotated:event.rotation];
}


#pragma mark histogram

-(void)toggleHistogram{
    if(self.reserveImage){
        self.imageView.image = self.reserveImage;
        self.reserveImage = nil;
    }else{
        //CIContext* context = [[NSGraphicsContext currentContext] CIContext];
        //NSBitmapImageRep *imageRep = (NSBitmapImageRep *)[self.imageView.image representations][0];
        NSData *imageData = [self.imageView.image TIFFRepresentation];
        NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
        CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:imageRep];
        
        CIImage *hist = [ciImage imageByApplyingFilter:@"CIAreaHistogram"
                                   withInputParameters:@{ @"inputCount": @256 }];
        
        CIImage *outputImage = [hist imageByApplyingFilter:@"CIHistogramDisplayFilter"
                                       withInputParameters:nil];
        
        
        NSCIImageRep *outRep = [NSCIImageRep imageRepWithCIImage: outputImage];
        NSImage *outNSImage = [[NSImage alloc] init];
        [outNSImage addRepresentation: outRep];
        //CGImageRef cgImage2 = [context createCGImage:ciImage fromRect:ciImage.extent];
        //NSImage *img2 = [[NSImage alloc] initWithCGImage:cgImage2 size:ciImage.extent.size];
        
        self.reserveImage = self.imageView.image;
        self.imageView.image = outNSImage;
    }
    
}
//

//
//-(NSRect)rectOfImage{
//    NSRect imageRect = [self.cell drawingRectForBounds:self.bounds];
//    return imageRect;
//}
//
//-(CGSize)sizeOfPictureInImageViewFrame{
//    
//    CGPoint origin = [self originOfContainedImage];
//    return CGSizeMake(self.bounds.size.width - 2 * origin.x, self.bounds.size.height - 2 * origin.y);
//}
//
//-(CGSize)sizeOfPictureInImageViewFrameMethod2{
//    
//    NSRect rect = [self rectOfImage];
//    return rect.size;
//}
//


@end
