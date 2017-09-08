//
//  NSOpenGLView+Utilities.m
//  IMCReader
//
//  Created by Raul Catena on 10/2/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "NSOpenGLView+Utilities.h"
#import <OpenGL/gl.h>

@implementation NSOpenGLView (Utilities)

static void memxor(unsigned char *dst, unsigned char *src, unsigned int bytes)
{
    while (bytes--) *dst++ ^= *src++;
}

static void memswap(unsigned char *a, unsigned char *b, unsigned int bytes)
{
    memxor(a, b, bytes);
    memxor(b, a, bytes);
    memxor(a, b, bytes);
}


//- (NSImage*) imageFromView
//{
//    
//    NSRect bounds = [self bounds];
//    int height = bounds.size.height;
//    int width = bounds.size.width;
//    
//    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
//                                  initWithBitmapDataPlanes:NULL
//                                  pixelsWide:width
//                                  pixelsHigh:height
//                                  bitsPerSample:8
//                                  samplesPerPixel:4
//                                  hasAlpha:YES
//                                  isPlanar:NO
//                                  colorSpaceName:NSDeviceRGBColorSpace
//                                  bytesPerRow:4 * width
//                                  bitsPerPixel:0
//                                  ];
//    
//    // This call is crucial, to ensure we are working with the correct context
//    [[self openGLContext] makeCurrentContext];
//    
//    GLuint framebuffer, renderbuffer;
//    GLenum status;
//    // Set the width and height appropriately for your image
//    GLuint imageWidth = width, imageHeight = height;
//    //Set up a FBO with one renderbuffer attachment
//    glGenFramebuffersEXT(1, &framebuffer);
//    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, framebuffer);
//    glGenRenderbuffersEXT(1, &renderbuffer);
//    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, renderbuffer);
//    glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_RGBA8, imageWidth, imageHeight);
//    glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
//                                 GL_RENDERBUFFER_EXT, renderbuffer);
//    status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
//    if (status != GL_FRAMEBUFFER_COMPLETE_EXT){
//        // Handle errors
//    }
//    //Your code to draw content to the renderbuffer
//    [self drawRect:[self bounds]];
//    //Your code to use the contents
//    glReadPixels(0, 0, width, height,
//                 GL_RGBA, GL_UNSIGNED_BYTE, [imageRep bitmapData]);
//    
//    // Make the window the target
//    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
//    // Delete the renderbuffer attachment
//    glDeleteRenderbuffersEXT(1, &renderbuffer);
//    
//    NSImage *image=[[NSImage alloc] initWithSize:NSMakeSize(width,height)];
//    [image addRepresentation:imageRep];
//    [image setFlipped:YES];
//    [image lockFocusOnRepresentation:imageRep]; // This will flip the rep.
//    [image unlockFocus];
//    
//    
//    return image;
//    
//}

- (NSImage *) imageFromViewOld
{
    NSRect bounds;
    int height, width, row, bytesPerRow;
    NSBitmapImageRep *imageRep;
    unsigned char *bitmapData;
    NSImage *image;
    
    bounds = [self bounds];
    
    height = bounds.size.height;
    width = bounds.size.width;
    
    imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                                       pixelsWide: width
                                                       pixelsHigh: height
                                                    bitsPerSample: 8
                                                  samplesPerPixel: 4
                                                         hasAlpha: YES
                                                         isPlanar: NO
                                                   colorSpaceName: NSCalibratedRGBColorSpace
                                                      bytesPerRow: 0				// indicates no empty bytes at row end
                                                     bitsPerPixel: 0];
				
    [[self openGLContext] makeCurrentContext];
				
    bitmapData = [imageRep bitmapData];
    
    bytesPerRow = (int)[imageRep bytesPerRow];
    
    glPixelStorei(GL_PACK_ROW_LENGTH, 8*bytesPerRow/[imageRep bitsPerPixel]);
    
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, bitmapData);
    
    // Flip the bitmap vertically to account for OpenGL coordinate system difference
    // from NSImage coordinate system.
    
    for (row = 0; row < height/2; row++)
    {
        unsigned char *a, *b;
        
        a = bitmapData + row * bytesPerRow;
        b = bitmapData + (height - 1 - row) * bytesPerRow;
        
        memswap(a, b, bytesPerRow);
    }
    
    // Create the NSImage from the bitmap
    
    image = [[NSImage alloc] initWithSize: NSMakeSize(width, height)];
    [image addRepresentation: imageRep];
    
    
    // Previously we did not flip the bitmap, and instead did [image setFlipped:YES];
    // This does not work properly (i.e., the image remained inverted) when pasting 
    // the image to AppleWorks or GraphicConvertor.
    
    return image;
}

@end
