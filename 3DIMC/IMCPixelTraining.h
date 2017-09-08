//
//  IMCPixelTraining.h
//  3DIMC
//
//  Created by Raul Catena on 2/16/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"
#import "IMCImageStack.h"

@interface IMCPixelTraining : IMCNodeWrapper

@property (nonatomic, readonly) IMCImageStack *imageStack;
@property (nonatomic, readonly) IMCPixelMap *whichMap;

/////@property (nonatomic, readonly) NSString *relFilePath;
@property (nonatomic, readonly) NSArray *trainingLabels;
@property (nonatomic, readonly) NSArray *learningSettings;
@property (nonatomic, readonly) BOOL isSegmentation;
@property (nonatomic, assign) UInt8 * trainingBuffer;

-(void)loadBuffer;


@end
