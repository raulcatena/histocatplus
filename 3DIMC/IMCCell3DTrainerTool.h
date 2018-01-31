//
//  IMCCell3DTrainerTool.h
//  3DIMC
//
//  Created by Raul Catena on 11/22/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCCellTrainerTool.h"

@interface IMCCell3DTrainerTool : IMCCellTrainerTool

@property (nonatomic, weak) IBOutlet NSSlider *planeSelector;
@property (weak) IBOutlet NSSlider *saturate;

@end
