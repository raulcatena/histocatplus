//
//  IMCButtonLayer.h
//  3DIMC
//
//  Created by Raul Catena on 3/1/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    PIXEL_LAYER_DIRECT = 1,
    PIXEL_LAYER_GB_3,
    PIXEL_LAYER_GB_5,
    PIXEL_LAYER_GB_7,
    PIXEL_LAYER_GB_9,
    PIXEL_LAYER_GB_11,
    PIXEL_LAYER_GB_21,
    PIXEL_LAYER_GB_51,
    PIXEL_LAYER_LOG_3,
    PIXEL_LAYER_LOG_5,
    PIXEL_LAYER_LOG_7,
    PIXEL_LAYER_LOG_9,
    PIXEL_LAYER_LOG_11,
    PIXEL_LAYER_LOG_21,
    PIXEL_LAYER_LOG_51,
    PIXEL_LAYER_CANNY_3,
    PIXEL_LAYER_CANNY_5,
    PIXEL_LAYER_CANNY_7,
    PIXEL_LAYER_CANNY_9,
    PIXEL_LAYER_CANNY_11,
    PIXEL_LAYER_CANNY_21,
    PIXEL_LAYER_CANNY_51,
    PIXEL_LAYER_GAUSSIAN_GRAD_3,
    PIXEL_LAYER_GAUSSIAN_GRAD_5,
    PIXEL_LAYER_GAUSSIAN_GRAD_7,
    PIXEL_LAYER_GAUSSIAN_GRAD_9,
    PIXEL_LAYER_GAUSSIAN_GRAD_11,
    PIXEL_LAYER_GAUSSIAN_GRAD_21,
    PIXEL_LAYER_GAUSSIAN_GRAD_51
} PixelLayerType;

@interface IMCButtonLayer : NSObject

@property (nonatomic, strong) NSString *channel;
@property (nonatomic, assign) PixelLayerType type;
@property (nonatomic, strong) IMCButtonLayer *parent;
@property (nonatomic, strong) NSMutableArray *children;

-(NSString *)nameForOption;
@end
