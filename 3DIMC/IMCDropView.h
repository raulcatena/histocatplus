//
//  DropView.h
//  IMCReader
//
//  Created by Raul Catena on 9/5/15.
//  Copyright (c) 2015 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DroppedURL <NSObject>

@optional
-(void)droppedFile:(NSURL *)urls;

@end

@interface IMCDropView : NSImageView <NSDraggingDestination>

@property (nonatomic, assign) IBOutlet id<DroppedURL>delegate;

@end
