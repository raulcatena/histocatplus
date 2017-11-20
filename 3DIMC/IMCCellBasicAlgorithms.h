//
//  IMCTSneWindowController.h
//  IMCReader
//
//  Created by Raul Catena on 9/12/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCMathWindowController.h"
#import "IMCGeneralPlot.h"
#import "IMCTsneDashboard.h"
#import "IMCKMeansDashboard.h"

@class IMC3DMask;

@interface IMCCellBasicAlgorithms : IMCMathWindowController<Plot>


@property (nonatomic, weak) IBOutlet IMCGeneralPlot *plot;
@property (nonatomic, weak) IBOutlet NSButton *startStop;
@property (nonatomic, weak) IBOutlet NSPopUpButton *colorVariable;
@property (nonatomic, weak) IBOutlet NSPopUpButton *colorVariable2;
@property (nonatomic, weak) IBOutlet NSPopUpButton *colorVariable3;
@property (nonatomic, weak) IBOutlet NSButton *colorVariableActive;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *coloringType;
@property (nonatomic, weak) IBOutlet NSSlider *burnColorPoints;
@property (nonatomic, weak) IBOutlet NSSlider *burnColorPoints2;
@property (nonatomic, weak) IBOutlet NSSlider *burnColorPoints3;
@property (nonatomic, weak) IBOutlet NSPopUpButton *choiceDRAlgorithm;
@property (nonatomic, weak) IBOutlet NSPopUpButton *choiceClustAlgorithm;
@property (nonatomic, weak) IBOutlet NSButton *showColor2;
@property (nonatomic, weak) IBOutlet NSButton *showColor3;
@property (nonatomic, weak) IBOutlet NSTableView *tableDR;
@property (nonatomic, weak) IBOutlet NSTableView *tableClust;
@property (nonatomic, weak) IBOutlet NSView *dashboardArea;
@property (nonatomic, weak) IBOutlet NSTextField *overrideXAxisLabel;
@property (nonatomic, weak) IBOutlet NSTextField *overrideYAxisLabel;
@property (nonatomic, weak) IBOutlet NSTextField *overrideTitleGraph;
@property (nonatomic, strong) IMCTsneDashboard *tsneDashboard;
@property (nonatomic, strong) IMCKMeansDashboard *kmenasDashboard;
@property (nonatomic, strong) NSString *mainURL;

-(IBAction)runReducer:(id)sender;
-(IBAction)runClusterer:(id)sender;
-(IBAction)changedColorPoints:(NSColorWell *)sender;
-(IBAction)changedSizePoints:(NSSlider *)sender;
-(IBAction)changedTransparencyPoints:(NSSlider *)sender;
-(IBAction)changedColorAxes:(NSColorWell *)sender;
-(IBAction)changedColorBckg:(NSColorWell *)sender;
-(IBAction)changedSizeAxes:(NSSlider *)sender;
-(IBAction)changedWidthAxes:(NSSlider *)sender;
-(IBAction)saveData:(NSButton *)sender;
-(IBAction)changedChoice:(NSPopUpButton *)sender;
-(IBAction)addDR:(id)sender;
-(IBAction)addClust:(id)sender;

-(IBAction)startStopCreateVideo:(NSButton *)sender;

-(instancetype)initWithComputation:(IMCComputationOnMask *)computation;
-(instancetype)initWith3DMask:(IMC3DMask *)computation;

-(BOOL)containsComputations:(NSArray<IMCComputationOnMask *>*)computations;

@end
