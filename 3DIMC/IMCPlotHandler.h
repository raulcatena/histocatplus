//
//  IMCPlotHandler.h
//  3DIMC
//
//  Created by Raul Catena on 2/26/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;
@class IMCChannelWrapper;
@class IMCGGPlot;

@protocol PlotHandler <NSObject>

-(NSInteger)typeOfPlot;
-(NSArray *)channelIndexesPlotting;
-(NSArray<IMCComputationOnMask *> *)computations;
-(NSInteger)xMode;
-(NSInteger)yMode;
-(NSInteger)cMode;
-(NSInteger)xChann;
-(NSInteger)yChann;
-(NSInteger)cChann;
-(NSInteger)sChann;
-(NSInteger)f1Chann;
-(NSInteger)f2Chann;
-(CGFloat)alphaGeomp;
-(CGFloat)sizeGeomp;
-(NSColor *)colorPointsChoice;
-(NSInteger)colorScaleChoice;

@end

@interface IMCPlotHandler : NSObject
@property (nonatomic, assign) id<PlotHandler>delegate;
@property (nonatomic, strong) IMCGGPlot * plotter;

-(NSImage *)getImageDerivedFromDelegate;
-(NSString *)getScriptDerivedFromDelegate;

@end
