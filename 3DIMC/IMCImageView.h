//
//  IMCDrawableImageView.h
//  IMCReader
//
//  Created by Raul Catena on 10/7/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCImageStack;

@interface IMCImageView : NSImageView

@property (nonatomic, strong) NSArray<IMCImageStack *> *stacks;

//Special properties
-(CGRect)selectedRect;
-(void)setSelectedArea:(CGRect)area;
-(CGRect)selectedArea;

-(CGRect)selectedRectProportions;
-(NSPoint)originOfContainedImage;
-(NSPoint)topOriginOfContainedImage;
-(NSPoint)yFlippedtopOriginOfContainedImage;
-(NSRect)photoRectInImageView;

//Legends and channel labels
-(void)addScaleWithScaleFactor:(float)factor color:(NSColor *)color fontSize:(float)fontSize widthPhoto:(NSInteger)width stepForced:(NSInteger)forceStep onlyBorder:(BOOL)onlyBorder static:(BOOL)staticBar;
-(void)removeScale;
-(void)setLabels:(NSArray *)titles withColors:(NSArray *)colors backGround:(NSColor *)backgroundColor fontSize:(CGFloat)fontSize vAlign:(BOOL)vAlign static:(BOOL)staticLabels;
-(void)removeLabels;
@end
