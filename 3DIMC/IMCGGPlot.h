//
//  IMCGGPlot.h
//  3DIMC
//
//  Created by Raul Catena on 2/24/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;
@class IMCChannelWrapper;

@interface IMCGGPlot : NSOperation

//-(void)exampleR;
//-(NSImage *)exampleWithTemplate;

-(NSString *)scatterPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;
-(NSString *)boxPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;
-(NSString *)histogramPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;
-(NSString *)linePlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;
-(NSString *)heatMapPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;

-(void)prepareDataMultiImage:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray<IMCChannelWrapper *> *)channels;

-(NSImage *)runWithScript:(NSString *)rScript;

-(NSString *)rScriptWithPlotType:(NSString *)plotType WithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale;

@end
