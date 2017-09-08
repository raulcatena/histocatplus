//
//  IMCPaintMask.h
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCThresholdMask.h"
#import "IMCBrushTools.h"


@interface IMCPaintMask : IMCThresholdMask<IMCScrollViewDelegate>

@property (nonatomic, weak) IMCBrushTools *brushTools;
@property (nonatomic, weak) IBOutlet NSView *brushToolsContainer;

@end
