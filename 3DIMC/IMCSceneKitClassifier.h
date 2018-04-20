//
//  IMCSceneKitClassifier.h
//  3DIMC
//
//  Created by Raul Catena on 4/16/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCCellTrainerTool.h"

@class IMCComputationOnMask;
@class IMCMaskTraining;

@interface IMCSceneKitClassifier : IMCCellTrainerTool

@property (nonatomic, strong) IMCComputationOnMask * cellData;

@end
