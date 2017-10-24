//
//  IMCThresholder.h
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCPixelClassification;
@class IMCImageStack;

@interface IMCThresholder : NSObject

@property (nonatomic, strong) IMCPixelClassification *mask;
@property (nonatomic, strong) IMCImageStack *stack;
@property (nonatomic, assign) int * paintMask;
@property (nonatomic, strong) NSString *thresholdingInfo;
@property (nonatomic, strong) NSMutableArray *options;

@property (nonatomic, assign) NSInteger channelIndex;
@property (nonatomic, assign) NSInteger framerIndex;
@property (nonatomic, assign) NSInteger blur;
@property (nonatomic, assign) NSInteger thresholdValue;
@property (nonatomic, assign) BOOL flatten;
@property (nonatomic, assign) BOOL isPaint;
@property (nonatomic, assign) BOOL saveInverse;
@property (nonatomic, strong) NSString * label;

-(void)saveMask;
-(void)generateBinaryMask;
-(CGImageRef)channelImage;
-(int *)processedMask;

@end
