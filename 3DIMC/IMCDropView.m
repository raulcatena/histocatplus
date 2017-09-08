//
//  DropView.m
//  IMCReader
//
//  Created by Raul Catena on 9/5/15.
//  Copyright (c) 2015 CatApps. All rights reserved.
//

#import "IMCDropView.h"

@implementation IMCDropView

-(id)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self registerForDraggedTypes:[NSImage imageTypes]];
        //[self registerForDraggedTypes:@[NSPasteboardTypeTIFF]];//Only TIFF
    }
    return self;
}

-(NSDragOperation)isAnImage:(id<NSDraggingInfo>)sender{
    return NSDragOperationCopy;//This will get anything
    
//    if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]] && [sender draggingSourceOperationMask] & NSDragOperationCopy) {
//        //NSLog(@"Is image and can copy");
//        return NSDragOperationCopy;
//    }
//    NSLog(@"Is not an image");
//    return NSDragOperationNone;
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    return [self isAnImage:sender];
}

-(NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender{//We don't need it
    //NSLog(@"Updating the dragging");
    return [self isAnImage:sender];
}

-(void)draggingEnded:(id<NSDraggingInfo>)sender{
    
}

-(void)draggingExited:(id<NSDraggingInfo>)sender{
    
}

-(BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender{
    
    return YES;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]]) {
        self.image = [[NSImage alloc]initWithPasteboard:[sender draggingPasteboard]];
    }
    return YES;
}

-(void)concludeDragOperation:(id<NSDraggingInfo>)sender{

    
    NSPasteboard *pasteboard = [sender draggingPasteboard];

    NSArray *classes = @[
                        [NSImage class],
                        [NSURL class]
                        ];
    
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    for (id file in copiedItems) {
        //NSURL *URL = [NSURL URLFromPasteboard:pasteboard];
//        NSURL *URL = (NSURL *)file;
//        NSLog(@"URL %@", URL.path);
        if([file isMemberOfClass:[NSURL class]])
            [self.delegate droppedFile:(NSURL *)file];
    }
}

@end
