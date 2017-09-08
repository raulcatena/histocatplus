//
//  IMCColorLegend.h
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ColorLegend <NSObject>

@end

@interface IMCColorLegend : NSView

@property (nonatomic, weak) id<ColorLegend>delegate;
@property (nonatomic, strong) NSArray * colorsForLegend;
@property (nonatomic, strong) NSArray * minsForLegend;//NSNumbers
@property (nonatomic, strong) NSArray * maxsForLegend;//NSNumbers
@property (nonatomic, strong) NSArray * maxOffsetsForLegend;//NSNumbers
@property (nonatomic, strong) NSArray * inflexionPointsForLegend;//NSNumbers
@property (nonatomic, assign) BOOL isHeatForLegend;
@property (nonatomic, assign) NSInteger hueStartForLegend;
@property (nonatomic, assign) NSInteger hueRangeForLegend;
@property (nonatomic, assign) BOOL hueCounterClockwiseForLegend;

@end
