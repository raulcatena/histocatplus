//
//  IMCPixelMap.h
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCImageStack.h"

@interface IMCPixelMap : IMCImageStack

@property (nonatomic, readonly) IMCImageStack *imageStack;
@property (nonatomic, readonly) IMCPixelTraining *whichTraining;
@property (nonatomic, assign) BOOL isSegmentation;

-(CGImageRef)pMap;
-(void)savePixelMapPredictions;
-(void)saveColorizedPixelMapPredictions;

@end
