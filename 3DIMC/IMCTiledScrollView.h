//
//  IMCTiledScrollView.h
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCScrollView.h"

@interface IMCTiledScrollView : IMCScrollView

@property (nonatomic, assign) BOOL scrollSubpanels;
@property (nonatomic, assign) BOOL syncronised;

@property (nonatomic, assign) BOOL showScaleBars;
@property (nonatomic, assign) NSInteger scaleStep;
@property (nonatomic, assign) CGFloat scaleFontSize;
@property (nonatomic, assign) CGFloat scaleCalibration;

@property (nonatomic, assign) BOOL showImageNames;

@property (nonatomic, assign) BOOL showLegendChannels;
@property (nonatomic, strong) NSColor *legendColor;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *imageNames;
@property (nonatomic, strong) NSArray *colorLegends;
@property (nonatomic, assign) CGFloat fontSizeLegends;

-(void)assembleTiledWithImages:(NSArray <NSImage *>*)images;

@end
