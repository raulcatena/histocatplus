//
//  IMCCellSegmenter.h
//  3DIMC
//
//  Created by Raul Catena on 3/6/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;

@interface IMCCellSegmenter : NSObject


+(void)saveCellProfilerPipelineWithImageWithWf:(NSString *)wf hash:(NSString *)hash minCellDiam:(NSString *)minCellDiam maxCellDiam:(NSString *)maxCellDiam lowThreshold:(NSString *)lowerThreshold upperThreshold:(NSString *)upperThreshold showIntermediate:(BOOL)showInter foreGround:(BOOL)foreground;

+(void)runCPSegmentationForeGround:(BOOL)foreground details:(BOOL)details onStack:(IMCImageStack *)stack withHash:(NSString *)hash withBlock:(void(^)(void))block inOwnThread:(BOOL)ownThread;

@end
