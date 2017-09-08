//
//  NSView+NSView_Utilities.m
//  IMCReader
//
//  Created by Raul Catena on 9/20/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "NSView+Utilities.h"

@implementation NSView (Utilities)

-(NSImage *)getImageBitMapFromRect:(CGRect)rect
{
    NSBitmapImageRep* imageRep=[self
                                bitmapImageRepForCachingDisplayInRect:rect];
    NSGraphicsContext *previousContext = [NSGraphicsContext
                                          currentContext];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext
                                          graphicsContextWithBitmapImageRep:imageRep]];
    [[NSColor clearColor] set];
    NSSize imageRepSize = [imageRep size];
 
    NSRectFill(NSMakeRect(0, 0, imageRepSize.width, imageRepSize.height));
    [NSGraphicsContext setCurrentContext:previousContext];
    [self cacheDisplayInRect:rect toBitmapImageRep:imageRep];
    NSImage* bitmapImage=[[NSImage alloc] initWithSize:rect.size];
    [bitmapImage addRepresentation:imageRep];
    return bitmapImage;
}

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

@end
