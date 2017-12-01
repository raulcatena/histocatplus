//
//  IMCGeneralPlot.h
//  IMCReader
//
//  Created by Raul Catena on 9/13/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCImageGenerator.h"

@protocol Plot <NSObject>

@optional
-(int *)biaxialData;
-(float *)floatBiaxialData;
-(int)numberOfDimensions;
-(int *)colorDataForThirdDimension;
-(NSDictionary *)titlesAndColorsDictionary;
-(BOOL)heatColorMode;
-(int)sizeOfData;
-(NSString *)topLabel;

-(float)maxOffSetX;
-(float)maxOffSetY;

-(NSArray *)channels;

@end

@interface IMCGeneralPlot : NSView

@property (nonatomic, strong) NSColor *backgroundColor;
@property (nonatomic, strong) NSColor *axesColor;
@property (nonatomic, strong) NSColor *pointsColor;
@property (nonatomic, strong) NSColor *backGroundCol;
@property (nonatomic, assign) float axesPointSize;
@property (nonatomic, assign) float sizePoints;
@property (nonatomic, assign) float transparencyPoints;
@property (nonatomic, assign) float thicknessAxes;
@property (nonatomic, strong) NSArray *titlesX;
@property (nonatomic, strong) NSArray *titlesXY;
@property (nonatomic, assign) BOOL logScale;
@property (nonatomic, assign) float cornerMargin;
@property (nonatomic, assign) BOOL legendOnRight;
@property (nonatomic, assign) float widthLegend;
@property (nonatomic, assign) float proportionX;
@property (nonatomic, assign) float proportionY;
@property (nonatomic, weak) id<Plot>delegatePlot;
@property (nonatomic, assign) float maxX;
@property (nonatomic, assign) float maxY;
@property (nonatomic, assign) float minX;
@property (nonatomic, assign) float minY;
@property (nonatomic, strong) NSColorSpace *colorSpace;

-(void)maxLabels:(CGContextRef)ref;
-(void)drawAxes:(CGContextRef)ctx;
-(void)drawLabels:(CGContextRef)ctx;
-(void)setBackGroundColor:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect;
-(void)addTopLabel:(NSString *)topTitle context:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect;
-(void)addTopLabels:(NSArray<NSString *>*)topTitles withColors:(NSArray<NSColor *>*)colors size:(CGFloat)size context:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect;

@end
