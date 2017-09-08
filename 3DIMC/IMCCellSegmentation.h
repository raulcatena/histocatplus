//
//  IMCCellSegmentation.h
//  3DIMC
//
//  Created by Raul Catena on 2/14/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelClassificationTool.h"
#import "IMCCellSegmenter.h"

@interface IMCCellSegmentation : IMCPixelClassificationTool

@property (nonatomic, weak) IBOutlet NSSegmentedControl *cpRunForeground;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *cpShowIntermediate;

@property (nonatomic, weak) IBOutlet NSTextField *minCellDiam;
@property (nonatomic, weak) IBOutlet NSTextField *maxCellDiam;
@property (nonatomic, weak) IBOutlet NSTextField *lowerThreshold;
@property (nonatomic, weak) IBOutlet NSTextField *upperThreshold;

@property (nonatomic, weak) IBOutlet NSButton *showPMapNuc;
@property (nonatomic, weak) IBOutlet NSButton *showPMapCyt;
@property (nonatomic, weak) IBOutlet NSButton *showPMapMbr;

-(IBAction)imageAsIlastik:(NSButton *)sender;
-(IBAction)runProfilerPipelineWithImage:(NSButton *)sender;
-(IBAction)showResults:(NSButton *)sender;
-(IBAction)addMasksToStack:(NSButton *)sender;

@end
