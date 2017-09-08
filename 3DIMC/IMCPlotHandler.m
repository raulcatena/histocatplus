//
//  IMCPlotHandler.m
//  3DIMC
//
//  Created by Raul Catena on 2/26/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPlotHandler.h"
#import "IMCGGPlot.h"
#import "NSString+MD5.h"
#import "IMCChannelWrapper.h"

@interface IMCPlotHandler()

@end

@implementation IMCPlotHandler

-(IMCGGPlot *)plotter{
    if(!_plotter)_plotter = [[IMCGGPlot alloc]init];
    return _plotter;
}

-(NSImage *)getImageDerivedFromDelegate{
    NSString *script = [self getScriptDerivedFromDelegate];
    return [self.plotter runWithScript:script];
}

-(NSString *)getScriptDerivedFromDelegate{
    NSString *script;
    switch ([self.delegate typeOfPlot]) {
        case 0:
            script = [self histogram];
            break;
        case 1:
            script = [self scatter];
            break;
        case 2:
            script = [self heatmap];
            break;
        case 3:
            script = [self boxPlot];
            break;
        case 4:
            script = [self linePlot];
            break;
        default:
            break;
    }
    return script;
}

-(NSString *)boxPlot{
    
    return [self.plotter boxPlotWithComputations:[self.delegate computations]
                                              channels:[self.delegate channelIndexesPlotting]
                                                 xMode:[self.delegate xMode]
                                                 yMode:[self.delegate yMode]
                                                 cMode:[self.delegate cMode]
                                              channelX:[self.delegate xChann]
                                              channelY:[self.delegate yChann]
                                              channelC:[self.delegate cChann]
                                              channelS:[self.delegate sChann]
                                             channelF1:[self.delegate f1Chann]
                                             channelF2:[self.delegate f2Chann]
                                                  size:[self.delegate sizeGeomp]
                                                 alpha:[self.delegate alphaGeomp]
                                           colorPoints:[self.delegate colorPointsChoice]
                                            colorScale:[self.delegate colorScaleChoice]
                                                    ];
    
}

-(NSString *)linePlot{
    
    return [self.plotter linePlotWithComputations:[self.delegate computations]
                                        channels:[self.delegate channelIndexesPlotting]
                                           xMode:[self.delegate xMode]
                                           yMode:[self.delegate yMode]
                                           cMode:[self.delegate cMode]
                                        channelX:[self.delegate xChann]
                                        channelY:[self.delegate yChann]
                                        channelC:[self.delegate cChann]
                                        channelS:[self.delegate sChann]
                                       channelF1:[self.delegate f1Chann]
                                       channelF2:[self.delegate f2Chann]
                                            size:[self.delegate sizeGeomp]
                                           alpha:[self.delegate alphaGeomp]
                                     colorPoints:[self.delegate colorPointsChoice]
                                      colorScale:[self.delegate colorScaleChoice]
                                                    ];
    
}

-(NSString *)histogram{
    
    return [self.plotter histogramPlotWithComputations:[self.delegate computations]
                                            channels:[self.delegate channelIndexesPlotting]
                                               xMode:[self.delegate xMode]
                                               yMode:[self.delegate yMode]
                                               cMode:[self.delegate cMode]
                                            channelX:[self.delegate xChann]
                                            channelY:[self.delegate yChann]
                                            channelC:[self.delegate cChann]
                                            channelS:[self.delegate sChann]
                                           channelF1:[self.delegate f1Chann]
                                           channelF2:[self.delegate f2Chann]
                                                size:[self.delegate sizeGeomp]
                                               alpha:[self.delegate alphaGeomp]
                                         colorPoints:[self.delegate colorPointsChoice]
                                          colorScale:[self.delegate colorScaleChoice]
                                                    ];
    
}
-(NSString *)scatter{
    
    return [self.plotter scatterPlotWithComputations:[self.delegate computations]
                                            channels:[self.delegate channelIndexesPlotting]
                                               xMode:[self.delegate xMode]
                                               yMode:[self.delegate yMode]
                                               cMode:[self.delegate cMode]
                                            channelX:[self.delegate xChann]
                                            channelY:[self.delegate yChann]
                                            channelC:[self.delegate cChann]
                                            channelS:[self.delegate sChann]
                                           channelF1:[self.delegate f1Chann]
                                           channelF2:[self.delegate f2Chann]
                                                size:[self.delegate sizeGeomp]
                                               alpha:[self.delegate alphaGeomp]
                                         colorPoints:[self.delegate colorPointsChoice]
                                          colorScale:[self.delegate colorScaleChoice]
                                                    ];
}
-(NSString *)heatmap{
    
    return [self.plotter heatMapPlotWithComputations:[self.delegate computations]
                                            channels:[self.delegate channelIndexesPlotting]
                                               xMode:[self.delegate xMode]
                                               yMode:[self.delegate yMode]
                                               cMode:[self.delegate cMode]
                                            channelX:[self.delegate xChann]
                                            channelY:[self.delegate yChann]
                                            channelC:[self.delegate cChann]
                                            channelS:[self.delegate sChann]
                                           channelF1:[self.delegate f1Chann]
                                           channelF2:[self.delegate f2Chann]
                                                size:[self.delegate sizeGeomp]
                                               alpha:[self.delegate alphaGeomp]
                                         colorPoints:[self.delegate colorPointsChoice]
                                          colorScale:[self.delegate colorScaleChoice]
                                                    ];
}


@end
