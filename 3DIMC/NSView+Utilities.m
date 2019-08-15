//
//  NSView+NSView_Utilities.m
//  IMCReader
//
//  Created by Raul Catena on 9/20/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "NSView+Utilities.h"

@implementation NSView (Utilities)

-(NSImage *)getImageBitMapFull
{
    NSBitmapImageRep* imageRep=[self
                                bitmapImageRepForCachingDisplayInRect:self.bounds];
    NSGraphicsContext *previousContext = [NSGraphicsContext
                                          currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:imageRep]];
    [[NSColor clearColor] set];
    NSSize imageRepSize = [imageRep size];
    
    NSRectFill(NSMakeRect(0, 0, imageRepSize.width, imageRepSize.height));
    [NSGraphicsContext setCurrentContext:previousContext];
    [self cacheDisplayInRect:self.bounds toBitmapImageRep:imageRep];
    NSImage* bitmapImage=[[NSImage alloc] initWithSize:self.frame.size];
    [bitmapImage addRepresentation:imageRep];
    return bitmapImage;
}


+ (NSView *)loadWithNibNamed:(NSString *)nibNamed owner:(id)owner class:(Class)loadClass {
    
    NSNib * nib = [[NSNib alloc] initWithNibNamed:nibNamed bundle:nil];
    
    NSArray * objects;
    if (![nib instantiateWithOwner:owner topLevelObjects:&objects]) {
        NSLog(@"Couldn't load nib named %@", nibNamed);
        return nil;
    }

    for (id object in objects) {
        if ([object isKindOfClass:loadClass]) {
            return object;
        }
    }
    return nil;
}
-(NSImage *)getImageBitMapFromRect:(CGRect)rect
{
    NSBitmapImageRep* imageRep=[self bitmapImageRepForCachingDisplayInRect:rect];
    NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
    [[NSColor clearColor] set];
    NSSize imageRepSize = [imageRep size];
    NSRectFill(NSMakeRect(0, 0, imageRepSize.width, imageRepSize.height));
    [NSGraphicsContext setCurrentContext:previousContext];
    [self cacheDisplayInRect:rect toBitmapImageRep:imageRep];
    NSImage* bitmapImage=[[NSImage alloc] initWithSize:rect.size];
    [bitmapImage addRepresentation:imageRep];
    return bitmapImage;
}
- (UInt8 *)bufferForView {
    
    NSRect rect = [self bounds];
    
    NSBitmapImageRep* imageRep=[self bitmapImageRepForCachingDisplayInRect:rect];
    NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imageRep]];
    [[NSColor clearColor] set];
    NSSize imageRepSize = [imageRep size];
    
    NSRectFill(NSMakeRect(0, 0, imageRepSize.width, imageRepSize.height));
    [NSGraphicsContext setCurrentContext:previousContext];
    [self cacheDisplayInRect:rect toBitmapImageRep:imageRep];
    NSImage* bitmapImage=[[NSImage alloc] initWithSize:rect.size];
    [bitmapImage addRepresentation:imageRep];
    
    NSSize imageSize = bitmapImage.size;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             imageSize.width,
                                             imageSize.height,
                                             8,
                                             imageSize.width * 4,
                                             colorSpace,
                                             kCGImageAlphaPremultipliedLast);
    
    
    // Wrap graphics context
    
    NSGraphicsContext* gctx = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
    
    // Make our bitmap context current and render the NSImage into it
    
    [NSGraphicsContext setCurrentContext:gctx];
    [bitmapImage drawInRect:rect];
    
    UInt8* pixeldata = (UInt8*)CGBitmapContextGetData(ctx);
    NSInteger lengthBuffer = imageSize.width * imageSize.height * 4;
    UInt8* copy = (UInt8*)malloc(lengthBuffer);
    
    for (NSInteger i = 0; i < lengthBuffer; i+=4){
        copy[i+0] = pixeldata[i+2];
        copy[i+1] = pixeldata[i+1];
        copy[i+2] = pixeldata[i+0];
        copy[i+3] = pixeldata[i+3];
    }
        
    
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    return copy;
}

@end
