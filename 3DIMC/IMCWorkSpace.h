//
//  Document.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCLoader.h"
#import "IMCScrollView.h"
#import "IMCTiledScrollView.h"
#import "IMCChannelSettingsDelegate.h"
#import "IMCBlendModes.h"
#import "IMCColorLegend.h"
#import "IMCTransformDictController.h"
#import "OpenGLView.h"
#import "IMCDropView.h"
#import "IMCTableDelegate.h"
#import "IMCMetadataTableDelegate.h"
#import "IMCPlotHandler.h"
#import "IMCPixelClassificationBatch.h"
#import "IMCSegmentationBatch.h"
#import "IMCCombineMasks.h"
#import "IMCCellClassificationBatch.h"
#import "IMCThresholdBatch.h"
#import "IMCMetricsController.h"
#import "IMCMetalViewAndRenderer.h"
#import "IMCMtkView.h"
#import "IMC3dMasking.h"


@class IMCImageStack;
@class IMCPixelClassification;
@class IMCComputationOnMask;
@class IMC3DHandler;

@interface IMCWorkSpace : NSDocument<DataCoordinator, CustomChannelsTableController, ColorLegend, NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate, NSTableViewDataSource, NSTabViewDelegate, NSTextFieldDelegate, IMCScrollViewDelegate, IMCScrollViewRotationDelegate, TransformDelegate, Get3DData, DroppedURL, TableDelegate, MetadataTableDelegate, PlotHandler, IMCPixelClassificationBatch, IMCCellSegmenationBatch, MaskCombiner, IMCCellClassificationBatch, IMCThresholdBatch, NSWindowDelegate, IMC3DMasker>


//Common

@property (nonatomic, strong) IMCLoader *dataCoordinator;
@property (nonatomic, strong) IMCImageStack *inScopeImage;
@property (nonatomic, strong) IMCPixelClassification *inScopeMask;
@property (nonatomic, strong) IMCComputationOnMask *inScopeComputation;
@property (nonatomic, strong) IMC3DMask *inScope3DMask;
@property (nonatomic, strong) NSMutableArray<IMCImageStack *> *inScopeImages;
@property (nonatomic, strong) NSMutableArray<IMCFileWrapper *> *inScopeFiles;
@property (nonatomic, strong) NSMutableArray<IMCPixelClassification *> *inScopeMasks;
@property (nonatomic, strong) NSMutableArray<IMCComputationOnMask *> *inScopeComputations;
@property (nonatomic, strong) NSMutableArray<IMC3DMask *> *inScope3DMasks;
@property (nonatomic, strong) NSMutableArray<NSImage *> *inScopePanoramas;
@property (nonatomic, strong) NSMutableArray *involvedStacksForMetadata;
@property (nonatomic, strong) NSMutableArray *inOrderIndexes;
@property (nonatomic, strong) NSMutableArray *channelsInScopeForPlotting;
@property (nonatomic, strong) IMCChannelSettingsDelegate *customChannelsDelegate;
@property (nonatomic, strong) IMCTableDelegate *tableDelegate;
@property (nonatomic, strong) IMCMetadataTableDelegate *metadataTableDelegate;
@property (nonatomic, strong) IMC3DHandler *threeDHandler;

@property (nonatomic, weak) IBOutlet NSMenuItem *analysis;
@property (nonatomic, weak) IBOutlet NSOutlineView *filesTree;
@property (nonatomic, weak) IBOutlet NSTextField * objectsTag;
@property (nonatomic, weak) IBOutlet NSTextField * channelsTag;
@property (nonatomic, weak) IBOutlet NSPopUpButton *whichTableCoordinator;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *whichTableChannels;
@property (nonatomic, weak) IBOutlet NSTableView *channels;
@property (nonatomic, weak) IBOutlet NSTableView *channelsCustom;
@property (nonatomic, weak) IBOutlet NSScrollView *channelsSV;
@property (nonatomic, weak) IBOutlet NSScrollView *channelsCustomSV;
@property (nonatomic, weak) IBOutlet NSTextField *memoryUsage;
@property (nonatomic, weak) IBOutlet NSTextField *sizeImage;
@property (nonatomic, weak) IBOutlet NSTextField *statsInfo;
@property (nonatomic, weak) IBOutlet NSTabView *tabs;
@property (nonatomic, weak) IBOutlet IMCColorLegend *colorLegend;
@property (nonatomic, weak) IBOutlet NSView *toolsContainer;
@property (nonatomic, weak) IBOutlet NSView *alignmentToolsContainer;
@property (nonatomic, weak) IBOutlet NSButton * pushItemUp;
@property (nonatomic, weak) IBOutlet NSButton * pushItemDown;
@property (nonatomic, weak) IBOutlet IMCDropView * dropView;
@property (nonatomic, weak) IBOutlet NSTextField * searchTree;
@property (nonatomic, weak) IBOutlet NSTextField * searchChannels;

//Blendtab//Tilestab
@property (nonatomic, weak) IBOutlet NSSegmentedControl *colorSpaceSelector;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *transformSpaceSelector;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *maskVisualizeSelector;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *maskPartsSelector;
@property (nonatomic, weak) IBOutlet NSPopUpButton *multiImageFilters;
@property (nonatomic, weak) IBOutlet NSPopUpButton *multiImageMode;
@property (nonatomic, weak) IBOutlet NSButton *scaleBar;
@property (nonatomic, weak) IBOutlet NSButton *scaleBarStatic;
@property (nonatomic, weak) IBOutlet NSColorWell *scaleBarColor;
@property (nonatomic, weak) IBOutlet NSColorWell *lengendsBackgroundColor;
@property (nonatomic, weak) IBOutlet NSTextField *scaleBarCalibration;
@property (nonatomic, weak) IBOutlet NSStepper *scaleBarSteps;
@property (nonatomic, weak) IBOutlet NSStepper *scaleBarFontSize;
@property (nonatomic, weak) IBOutlet NSButton *legends;
@property (nonatomic, weak) IBOutlet NSButton *showNames;
@property (nonatomic, weak) IBOutlet NSButton *legendsStatic;
@property (nonatomic, weak) IBOutlet NSButton *legendsVertical;
@property (nonatomic, weak) IBOutlet NSStepper *legendsFontSize;
@property (nonatomic, weak) IBOutlet NSStepper *gaussianBlur;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *blur;
@property (nonatomic, weak) IBOutlet NSButton *brightFieldEffect;


//Blendtab
@property (nonatomic, weak) IBOutlet NSView *blendToolsContainer;
@property (nonatomic, weak) IBOutlet IMCTiledScrollView *scrollViewBlends;
@property (nonatomic, weak) IBOutlet NSPopUpButton *applyTransfomrs;
@property (nonatomic, weak) IBOutlet NSButton *autoRefreshLock;

//Tilestab
@property (nonatomic, weak) IBOutlet IMCTiledScrollView *scrollViewTiles;
@property (nonatomic, weak) IBOutlet NSView *tilesToolsContainer;
@property (nonatomic, weak) IBOutlet NSPopUpButton *scrollSubpanels;
-(IBAction)changedPanelScrollingType:(NSPopUpButton *)sender;

//3DAlignment
//@property (nonatomic, weak) IBOutlet NSSegmentedControl *speedAlignmentControl;
@property (nonatomic, weak) IBOutlet NSView *tilesToolsSubContainerTransformDict;
@property (nonatomic, weak) IMCTransformDictController *transformDictController;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *elasticTransform;
@property (nonatomic, weak) IBOutlet NSButton *pegAligns;
//@property (nonatomic, weak) IBOutlet NSButton *alignTwo;
//@property (nonatomic, weak) IBOutlet NSButton *alignAll;
@property (nonatomic, weak) IBOutlet NSView *threeDContainerView;
@property (nonatomic, weak) IBOutlet OpenGLView *openGlViewPort;
@property (nonatomic, weak) IBOutlet IMCMtkView *metalView;
@property (nonatomic, weak) IBOutlet NSColorWell *background3D;
@property (nonatomic, weak) IBOutlet NSSlider *thresholdToRender;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *alphaModeSelector;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *lightModeSelector;
@property (nonatomic, weak) IBOutlet NSStepper *stepperDefaultZ;
@property (nonatomic, weak) IBOutlet NSTextField *labelStepperDefaultZ;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *threeDProcessesIndicator;
@property (nonatomic, weak) IBOutlet NSPopUpButton *cleanUpMode;
@property (nonatomic, weak) IBOutlet NSPopUpButton *boostMode;
@property (nonatomic, weak) IBOutlet NSPopUpButton *videoType;

//TabPlotsTab
@property (nonatomic, weak) IBOutlet IMCScrollView *plotResult;
@property (nonatomic, weak) IBOutlet NSPopUpButton *plotType;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *xLog;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *yLog;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *cLog;
@property (nonatomic, weak) IBOutlet NSPopUpButton *xChannel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *yChannel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *cChannel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *sChannel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *f1Channel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *f2Channel;
@property (nonatomic, weak) IBOutlet NSSlider *alphaGeompSlider;
@property (nonatomic, weak) IBOutlet NSSlider *sizeGeompSlider;
@property (nonatomic, weak) IBOutlet NSColorWell *colorPoints;
@property (nonatomic, weak) IBOutlet NSPopUpButton *colorScale;

//TableEventstab
@property (nonatomic, weak) IBOutlet NSTableView *eventsTable;
@property (nonatomic, weak) IBOutlet NSButton *exportCSVButton;
@property (nonatomic, weak) IBOutlet NSButton *exportFCSButton;

//Compensation button
@property (nonatomic, weak) IBOutlet NSButton *compensationSwitch;

//TableMetadata
@property (nonatomic, weak) IBOutlet NSTableView *metadataTable;

//Analytics
@property (nonatomic, strong) IBOutlet IMCMetricsController *metricsController;
@property (nonatomic, weak) IBOutlet NSTableView *analyticsMetrics;
@property (nonatomic, weak) IBOutlet NSTableView *analyticsChannels;
@property (nonatomic, weak) IBOutlet NSTableView *analyticsFilterChannels;
@property (nonatomic, weak) IBOutlet NSTableView *analyticsResults;

//Menu methods
//Archive
-(IBAction)openImages:(NSButton *)sender;
-(IBAction)addMasksFromDirectory:(NSButton *)sender;
//Search
-(IBAction)searchTable:(NSTextField *)sender;
//Save pictures
-(IBAction)saveMultiPageTIFFs:(NSButton *)sender;
-(IBAction)saveMultiPageTIFFsWithSelected:(NSButton *)sender;
-(IBAction)saveTIFFStackInFolder:(NSButton *)sender;//for miCAT
-(IBAction)saveCurrentView:(NSButton *)sender;
-(IBAction)saveCurrentVisible:(NSButton *)sender;
-(IBAction)saveCurrentViewToWorkingDirectory:(NSButton *)sender;
-(IBAction)saveCurrentVisibleViewToWorkingDirectory:(NSButton *)sender;
//Override copy for copy to clipboard the whole image
-(IBAction)copyCurrentVisible:(NSButton *)sender;
-(IBAction)copyLegend:(NSButton *)sender;
-(IBAction)copy3Dpic:(id)sender;
//Order images
-(IBAction)pushImagesUpOrDown:(id)sender;
//Refresh
-(IBAction)changedWhiteBackground:(NSButton *)sender;
-(IBAction)refresh:(id)sender;
-(IBAction)updateTableView:(id)sender;
//Compensation
-(IBAction)flipCompensation:(NSButton *)sender;
//Registration
-(IBAction)alignSelected:(NSButton *)sender;
//3D
-(IBAction)start3Dreconstruction:(NSButton *)sender;
-(IBAction)redoZ:(NSButton *)sender;
-(IBAction)recordVideo:(NSButton *)sender;
-(IBAction)refresh3D:(id)sender;
-(IBAction)stepperZChanged:(id)sender;
//Segmentation
-(IBAction)segmentCells:(id)sender;
-(IBAction)segmentCellsBatch:(id)sender;
//Pixel Classification
-(IBAction)pixelClassify:(id)sender;
-(IBAction)pixelClassificatonBatch:(id)sender;
//ThresholdMaks
-(IBAction)thresholdMask:(id)sender;
-(IBAction)thresholdMaskBatch:(id)sender;
//Manual Mask
-(IBAction)manualMask:(id)sender;
//Gaussian Blur
-(IBAction)changedBlur:(id)sender;
//Plot
-(IBAction)refreshGGPlot:(id)sender;
-(IBAction)showRMiniConsole:(id)sender;
//Combine Masks
-(IBAction)combineMasks:(id)sender;
//Combine Masks
-(IBAction)cellClassification:(id)sender;
-(IBAction)cellClassificationBatch:(id)sender;
//Export events
-(IBAction)exportCSV:(id)sender;
-(IBAction)exportFCS:(id)sender;
//Metadata table
-(IBAction)addMetadataLabel:(id)sender;
-(IBAction)removeMetadataLabel:(id)sender;
-(IBAction)renameMetadataLabel:(id)sender;
-(IBAction)applySelectionBackwards:(id)sender;
-(IBAction)exportMetadataTSV:(id)sender;
//Analysis tools
-(IBAction)addMetric:(id)sender;
-(IBAction)removeMetric:(id)sender;
//Airlab
-(IBAction)cleanUpNamesWithAirlab:(id)sender;
//Compensation
-(IBAction)compensationMatrix:(id)sender;
//Masker
-(IBAction)showMasker:(id)sender;
-(IBAction)create3DMaskFromCurrent:(id)sender;
-(IBAction)create3DMaskByThresholding:(id)sender;
-(IBAction)create3DMaskByThresholdingKeepId:(id)sender;
-(IBAction)watershed2D:(id)sender;
//Cell Algorithms
-(IBAction)cellBasicAlgorithms:(id)sender;
-(IBAction)clusterKMeans:(id)sender;
-(IBAction)clusterFlock:(id)sender;

//Help
-(IBAction)helpHC:(NSButton *)sender;

@end

