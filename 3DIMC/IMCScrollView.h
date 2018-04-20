//
//  IMCScrollView.h
//  3DIMC
//
//  Created by Raul Catena on 1/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCImageView.h"
#import <Quartz/Quartz.h>
#import "IMCHistogram.h"

@class IMCScrollView;

@protocol IMCScrollViewDelegate <NSObject>
@optional
-(void)clickedAtPoint:(NSPoint)point;
-(void)doubleClickedAtPoint:(IMCScrollView *)scroll;
-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll;
-(void)scrolledWithScroll:(IMCScrollView *)scroll;
-(void)altScrolledWithEvent:(NSEvent *)event;
-(void)mouseUpCallback:(NSEvent *)event;
@end

@protocol IMCScrollViewRotationDelegate <NSObject>
@required
-(void)rotated:(float)rotation;
-(void)translated:(NSEvent *)eventTrans;
@end

@interface IMCScrollView : NSScrollView<IMCScrollViewDelegate>

@property (nonatomic, strong) IMCImageView *imageView;
@property (nonatomic, strong) IKImageView *iKimageView;
@property (nonatomic, strong) IMCHistogram *histogram;
@property (nonatomic, weak) id<IMCScrollViewDelegate>delegate;
@property (nonatomic, weak) id<IMCScrollViewRotationDelegate>rotationDelegate;
@property (nonatomic, assign) BOOL takingEvents;

//Calculations with points retrieve from delegate call
-(NSPoint)getTranslatedPoint:(NSPoint)point;

@end
