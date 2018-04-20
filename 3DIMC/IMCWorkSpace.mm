//
//  IMCWorkSpace.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCWorkSpace.h"
//Handlers
#import "IMCWorkspaceSelector.h"
#import "IMCWorkSpaceRefresher.h"

#import "NSTableView+ContextMenu.h"

//Wrappers
#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"
#import "IMCImageGenerator.h"
#import "IMCPixelTraining.h"
#import "IMCPixelClassification.h"
#import "IMCComputationOnMask.h"
#import "IMCPixelMap.h"

#import "NSImage+OpenCV.h"

#import "IMCFileExporter.h"
#import "IMCChannelOperations.h"
#import "NSView+Utilities.h"
#import "IMC3DHandler.h"
#import "IMCRegistration.h"
#import "IMCRegistrationOCV.h"
//Video
#import "NSOpenGLView+Utilities.h"
#import "IMC3DVideoPrograms.h"
//Segment and Pixel classif. ML
#import "IMCCellSegmentation.h"
#import "IMCPixelClassificationTool.h"
#import "IMCThresholdMask.h"
#import "IMCPaintMask.h"
//Cell Classificaton
#import "IMCCellTrainerTool.h"
#import "IMCCell3DTrainerTool.h"
#import "IMCSceneKitClassifier.h"

//RConsole
#import "IMCMiniRConsole.h"
#import "IMCGGPlot.h"

//Utils
#import "NSString+MD5.h"
#import "NSArray+Statistics.h"

//Airlab
#import "IMCAirLabClient.h"
//Compensation
#import "IMCCompensation.h"
//3DMask
#import "IMC3DMask.h"

//Watershed
#import "IMCWaterShedSegmenter.h"

//Cell basic algorithms
#import "IMCCellBasicAlgorithms.h"

//GLK
#import "Matrix4.h"

//Help
#import "Help.h"

//Positioning 3D
#import "IMCPositions.h"

@interface IMCWorkSpace (){
    dispatch_queue_t threadPainting;
    BOOL recordingVideo;
}

@property (nonatomic, strong) IMCWorkspaceSelector *workSpaceHandler;
@property (nonatomic, strong) IMCWorkSpaceRefresher *workSpaceRefresher;
@property (nonatomic, strong) IMCPlotHandler *plotHandler;
@property (nonatomic, strong) NSMutableArray *batchWindows;
@property (nonatomic, strong) IMCMiniRConsole *rMiniConsole;
@property (nonatomic, strong) IMCMetalViewAndRenderer *metalViewDelegate;
@property (nonatomic, strong) IMCMetalSphereRenderer *sphereMetalViewDelegate;
@property (nonatomic, strong) IMCMetalSphereRenderer *stripedSphereMetalViewDelegate;
@property (nonatomic, assign) NSModalSession compensationSession;
@property (nonatomic, strong) IMCCompensation * compensationHandler;
@property (nonatomic, strong) NSMutableArray<IMCCellBasicAlgorithms *> * cellAnalyses;
@property (nonatomic, strong) IMCCellBasicAlgorithms *currentCellAnalysis;
@property (nonatomic, strong) IMCPositions *positionsTool;

@end

@implementation IMCWorkSpace

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dataCoordinator = [[IMCLoader alloc]init];
        self.dataCoordinator.delegate = self;
        
        self.inScopeImages = @[].mutableCopy;//TODO make SETm
        self.inScopeFiles = @[].mutableCopy;//TODO make SETm
        self.inScopePanoramas = @[].mutableCopy;
        self.inScopeMasks = @[].mutableCopy;
        self.inScope3DMasks = @[].mutableCopy;
        self.inScopeComputations = @[].mutableCopy;
        self.involvedStacksForMetadata = @[].mutableCopy;
        self.batchWindows = @[].mutableCopy;
        
        self.customChannelsDelegate = [[IMCChannelSettingsDelegate alloc]init];
        self.customChannelsDelegate.delegate = self;
        
        self.tableDelegate = [[IMCTableDelegate alloc]init];
        self.tableDelegate.delegate = self;
        
        self.metadataTableDelegate = [[IMCMetadataTableDelegate alloc]init];
        self.metadataTableDelegate.delegate = self;
        
        self.metricsController = [[IMCMetricsController alloc]init];
        self.metricsController.parent = self;
        
        self.plotHandler = [[IMCPlotHandler alloc]init];
        self.plotHandler.delegate = self;
        
        self.workSpaceHandler = [[IMCWorkspaceSelector alloc]init];
        self.workSpaceHandler.parent = self;
        
        self.workSpaceRefresher = [[IMCWorkSpaceRefresher alloc]init];
        self.workSpaceRefresher.parent = self;
        
    }
    return self;
}

-(void)viewerOnly{
    while (self.tabs.tabViewItems.count > 3) {
        [self.tabs removeTabViewItem:[self.tabs tabViewItemAtIndex:3]];
    }
    self.applyTransfomrs.hidden = YES;
    self.applyTransfomrs = nil;
    self.multiImageFilters.hidden = YES;
}
-(void)noThreeD{
    while (self.tabs.tabViewItems.count > 5) {
        [self.tabs removeTabViewItem:[self.tabs tabViewItemAtIndex:5]];
    }
    self.applyTransfomrs.hidden = YES;
    self.applyTransfomrs = nil;
    self.multiImageFilters.hidden = YES;
}
-(void)checkWhich3DtechnologyForceLegacy:(BOOL)force{

    self.metalView.device = MTLCreateSystemDefaultDevice();
    
    if(self.metalView.device && force == NO){
        [self.openGlViewPort removeFromSuperview];
        self.openGlViewPort = nil;
        self.metalViewDelegate = [[IMCMetalViewAndRenderer alloc]init];
        self.sphereMetalViewDelegate = [[IMCMetalSphereRenderer alloc]init];
        self.stripedSphereMetalViewDelegate = [[IMCMetalSphereStripedRenderer alloc]init];
        self.metalView.delegate = self.metalViewDelegate;
        self.metalViewDelegate.delegate = self;
        self.sphereMetalViewDelegate.delegate = self;
        self.stripedSphereMetalViewDelegate.delegate = self;
    }else{
        [self.metalView removeFromSuperview];
        self.metalView = nil;
    }
}
-(void)restore3Dstate{
    if(self.metalView){
        if(self.dataCoordinator.baseModelMatrixMetal)
            [self.metalView.baseModelMatrix setMatrixFromStringRepresentation:self.dataCoordinator.baseModelMatrixMetal];
        
        if(self.dataCoordinator.rotationMatrixMetal)
            [self.metalView.rotationMatrix setMatrixFromStringRepresentation:self.dataCoordinator.rotationMatrixMetal];
        
        if(self.dataCoordinator.zoom)
            self.metalView.zoom = self.dataCoordinator.zoom.floatValue;
        [self.metalView applyRotationWithInternalState];
    }
    if(self.dataCoordinator.selectedRectString)
        [self.scrollViewBlends.imageView setSelectedArea:NSRectFromString(self.dataCoordinator.selectedRectString)];
}
- (void)awakeFromNib {
    
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"IMCChannelSettings" bundle:nil];
    [self.channelsCustom registerNib:nib forIdentifier: @"ChannelSettings"];
    self.channelsCustom.delegate = self.customChannelsDelegate;
    self.channelsCustom.dataSource = self.customChannelsDelegate;
    self.eventsTable.delegate = self.tableDelegate;
    self.eventsTable.dataSource = self.tableDelegate;
    self.metadataTable.delegate = self.metadataTableDelegate;
    self.metadataTable.dataSource = self.metadataTableDelegate;
        
    self.analyticsMetrics.delegate = self.metricsController;
    self.analyticsMetrics.dataSource = self.metricsController;
    self.analyticsChannels.delegate = self.metricsController;
    self.analyticsChannels.dataSource = self.metricsController;
    self.analyticsFilterChannels.delegate = self.metricsController;
    self.analyticsFilterChannels.dataSource = self.metricsController;
    self.analyticsResults.delegate = self.metricsController;
    self.analyticsResults.dataSource = self.metricsController;
    
    [self updateTableView:self.whichTableChannels];
    [self.filesTree setDoubleAction:@selector(openCloseClick:)];
    [self.channels setDoubleAction:@selector(channelsDoubleClick:)];
    [self.multiImageFilters addItemsWithTitles:[IMCBlendModes blendModes]];
    [self.multiImageFilters selectItemAtIndex:2];
    
    self.transformDictController = (IMCTransformDictController *)[NSView loadWithNibNamed: NSStringFromClass([IMCTransformDictController class]) owner:nil class:[IMCTransformDictController class]];
    [self.tilesToolsSubContainerTransformDict addSubview:self.transformDictController];
    self.transformDictController.delegate = self;
    self.threeDHandler = [[IMC3DHandler alloc]init];
    self.threeDHandler.loader = self.dataCoordinator;
    self.dropView.delegate = self;
    
    self.scrollViewBlends.delegate = self;
    
    self.colorSpaceSelector.selectedSegment = [[[NSUserDefaults standardUserDefaults]valueForKey:PREF_COLORSPACE]integerValue];
    
    if(VIEWER_ONLY)
        [self viewerOnly];
    if(VIEWER_HISTO)
        [self noThreeD];
//    if(VIEWER_ONLY || VIEWER_HISTO)
//        self.compensationSwitch.hidden = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [self checkWhich3DtechnologyForceLegacy:![[defaults valueForKey:PREF_USE_METAL] boolValue]];
    [self restore3Dstate];
}


- (NSString *)windowNibName {
    return NSStringFromClass(self.class);
}

#pragma mark Setters controller UI

-(void)setInScopeImage:(IMCImageStack *)inScopeImage{
    _inScopeImage = inScopeImage;
    if(!inScopeImage)return;
//    if(![self.inScopeImages containsObject:inScopeImage])
//        [self.inScopeImages addObject:inScopeImage];
    [self.workSpaceRefresher updateForWithStack:inScopeImage];
}
-(void)setInScopeMask:(IMCPixelClassification *)inScopeMask{
    _inScopeMask = inScopeMask;
    if(!inScopeMask)return;
    if(![self.inScopeMasks containsObject:inScopeMask])
        [self.inScopeMasks addObject:inScopeMask];
    [self.workSpaceRefresher updateForWithStack:inScopeMask.imageStack];
}
-(void)setInScopeComputation:(IMCComputationOnMask *)inScopeComputation{
    _inScopeComputation = inScopeComputation;
    if(!inScopeComputation)return;
    if(![self.inScopeComputations containsObject:inScopeComputation])
        [self.inScopeComputations addObject:inScopeComputation];
    [self.workSpaceRefresher updateForWithStack:inScopeComputation.mask.imageStack];
    self.customChannelsDelegate.settingsJsonArray = inScopeComputation.channelSettings;
}
-(void)setInScope3DMask:(IMC3DMask *)inScope3DMask{
    _inScope3DMask = inScope3DMask;
    if(inScope3DMask)
        self.scrollViewBlends.imageView.selectedArea = NSRectFromString(inScope3DMask.roiMask);
    if(inScope3DMask && self.inOrderIndexes.count == 0)
        self.inOrderIndexes = @[@(0)].mutableCopy;
    inScope3DMask.blurMode = self.cleanUpMode.indexOfSelectedItem;
    inScope3DMask.noBorders = (BOOL)self.with3Dgaps.indexOfSelectedItem;
    self.sphereMetalViewDelegate.computation = inScope3DMask;
    self.stripedSphereMetalViewDelegate.computation = inScope3DMask;
    self.customChannelsDelegate.settingsJsonArray = inScope3DMask.channelSettings;
}

#pragma mark File Handling

+ (BOOL)autosavesInPlace {
    return YES;
}

-(void)prepSave3D{
    if(VIEWER_ONLY || VIEWER_HISTO)
        return;
    
    if(self.metalView){
        self.dataCoordinator.baseModelMatrixMetal = self.metalView.baseModelMatrix.stringRepresentation;
        self.dataCoordinator.rotationMatrixMetal = self.metalView.rotationMatrix.stringRepresentation;
    }
    NSString *selArea = NSStringFromRect([self.scrollViewBlends.imageView selectedArea]);
    if(selArea)
        self.dataCoordinator.selectedRectString = selArea;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSError *error;
    [self.dataCoordinator updateOrderedImageList];
    
    //Saving 3D state
    [self prepSave3D];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.dataCoordinator.jsonDescription options:NSJSONWritingPrettyPrinted error:&error];
    if(error){
        NSLog(@"Error writing JSON description %@", error);
        return nil;
    }
    if (!data && outError) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFileWriteUnknownError userInfo:nil];
    }
    
    return data;
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    //[NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
}

-(void)shouldCloseWindowController:(NSWindowController *)windowController delegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo{
    //TODO prompt to save if it has not yet
    [self close];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSError *error;
    
    if([self.fileURL.pathExtension isEqualToString:EXTENSION_WORKSPACE]){
        NSMutableDictionary * json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (!data && outError)
            *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                            code:NSFileReadUnknownStringEncodingError userInfo:nil];
        
        if(error){
            NSLog(@"Error loading JSON description %@", error);
            return NO;
        }
        
        if(json){
            self.dataCoordinator.jsonDescription = json;
            [self.dataCoordinator updateFileWrappers];
            [self.dataCoordinator updateOrderedImageList];
        }
            return YES;
    }else{
        if([IMCLoader validFile:self.fileURL.path]){
            [self.dataCoordinator openImagesFromURL:@[self.fileURL]];
            self.fileURL = nil;
            self.fileType = EXTENSION_WORKSPACE;
            return YES;
        }
    }

    return NO;
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    //[NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    //return YES;
}


#pragma mark loading functions

-(BOOL)saveFirst{
    if(!self.fileURL){
        [General runAlertModalWithMessage:@"Save the document first. It is recommended that you save in the root of the folder where your images reside. It can be a folder with more subfolders where the images are"];
        [self saveDocument:nil];
        return YES;
    }
    return NO;
}

-(void)droppedFile:(NSURL *)url{
    if([self saveFirst])return;
    [self.dataCoordinator openImagesFromURL:@[url]];
    [self refresh];
}

-(void)openImages:(NSButton *)sender{
    if([self saveFirst])return;
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:YES];
    
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            [self.dataCoordinator openImagesFromURL:urls];
            [self refresh];
        }
    }];
}
-(void)addMasksFromDirectory:(NSButton *)sender{
    if(self.dataCoordinator.inOrderImageWrappers.count == 0)return;
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            [self.dataCoordinator tryMasksFromURL:urls.firstObject];
            [self refresh];
        }
    }];
}
-(void)openCloseClick:(NSOutlineView *)sender{
    if(self.filesTree.selectedRowIndexes.count > 1)return;
    IMCNodeWrapper *anobj = [self.filesTree itemAtRow:self.filesTree.selectedRow];
    if(!anobj.isLoaded)
        [anobj loadLayerDataWithBlock:^{
            [self refresh];
            [self.dataCoordinator updateOrderedImageList];
        }];
    else{
        if([anobj isMemberOfClass:[IMCPanoramaWrapper class]]){
            IMCPanoramaWrapper *pan = (IMCPanoramaWrapper *)anobj;
            NSImage *prevImage = pan.panoramaImage;
            if([self.inScopePanoramas containsObject:prevImage])
                [self.inScopePanoramas removeObject:prevImage];
            
            pan.after = !pan.after;
            [self.inScopePanoramas insertObject:pan.panoramaImage atIndex:0];
            [self refresh];
        }
        else
            [anobj unLoadLayerDataWithBlock:^{
                [self refresh];
            }];
    }
}
-(void)openFileWrapper:(IMCNodeWrapper *)item{
    if([item isMemberOfClass:[IMCFileWrapper class]]){
        IMCFileWrapper *wrapper = (IMCFileWrapper *)item;
        [wrapper loadFileWithBlock:^{
            self.inScopeImage = (IMCImageStack *)wrapper.children.firstObject.children.firstObject;
            [self.dataCoordinator updateOrderedImageList];
        }];
    }
}
-(void)channelsDoubleClick:(NSTableView *)tv{
    if(self.inScopeComputation || self.inScope3DMask)
        [self passChannel:[self.inScopeComputation?self.inScopeComputation : self.inScope3DMask wrappedChannelAtIndex:tv.selectedRow]];
    if(self.inScopeImage && self.inScopeImage.isLoaded)
        [self.inScopeImage setAutoMaxForMilenile:9999 andChannel:MIN(tv.selectedRow, self.inScopeImage.channels.count - 1)];
    [self refresh];
}
-(void)passChannel:(IMCChannelWrapper *)chann{
    if(!self.channelsInScopeForPlotting)
        self.channelsInScopeForPlotting = @[].mutableCopy;
    id found;
    for(IMCChannelWrapper *ch in self.channelsInScopeForPlotting)
        if(ch.index == chann.index){
            found = ch;
            break;
        }
    if(found)
        [self.channelsInScopeForPlotting removeObject:found];
    else
        [self.channelsInScopeForPlotting addObject:chann];
    
    [self.workSpaceRefresher refreshRControls];
}
-(void)pushImagesUpOrDownOld:(id)sender{
    
    NSInteger dir = sender == self.pushItemUp?-1:1;
    NSInteger index = self.filesTree.selectedRow;
    NSInteger count = self.dataCoordinator.inOrderImageWrappers.count;

    id tempObject = [self.dataCoordinator.inOrderImageWrappers objectAtIndex:self.filesTree.selectedRow];
    
    [self.dataCoordinator.inOrderImageWrappers replaceObjectAtIndex:index
                                                    withObject:[self.dataCoordinator.inOrderImageWrappers objectAtIndex:MAX(MIN(count - 1, index + dir), 0)]];
    
    
    [self.dataCoordinator.inOrderImageWrappers replaceObjectAtIndex:MAX(MIN(count - 1, index + dir), 0) withObject:tempObject];
    [self.filesTree selectRowIndexes:[NSIndexSet indexSetWithIndex:index + dir] byExtendingSelection:NO];
    [self.filesTree reloadData];
}
-(void)pushImagesUpOrDown:(id)sender{
    
    NSInteger dir = sender == self.pushItemUp?-1:1;
    NSInteger firstIndex = self.filesTree.selectedRowIndexes.firstIndex;
    NSInteger lastIndex = self.filesTree.selectedRowIndexes.lastIndex;
    NSInteger count = self.dataCoordinator.inOrderImageWrappers.count;
    NSMutableIndexSet *set = self.filesTree.selectedRowIndexes.mutableCopy;
    
    if(firstIndex <= 0 && dir == -1)return;
    if(lastIndex >= count - 1 && dir == 1)return;
    
    NSInteger insert = firstIndex + dir;
    
    NSArray * tempObjects = [self.dataCoordinator.inOrderImageWrappers objectsAtIndexes:set];
    [self.dataCoordinator.inOrderImageWrappers removeObjectsAtIndexes:set];
    
    [self.dataCoordinator.inOrderImageWrappers insertObjects:tempObjects atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insert, set.count)]];
    
    [set addIndex: dir + (dir == -1? firstIndex : lastIndex )];
    [set removeIndex: dir == -1? lastIndex : firstIndex];
    
    [self.filesTree selectRowIndexes:set byExtendingSelection:NO];
    [self.filesTree reloadData];
}

#pragma mark File exporting and copying
-(BOOL)checkThereIsImageInScopeAndChannelsSelected:(BOOL)channelsRequired{
    if(!self.inScopeImage){
        [General runAlertModalWithMessage:channelsRequired?@"You need to open and select one image stack and at least one channel first":@"You need to open and select one image stack first"];
        return NO;
    }
    return YES;
}
-(IBAction)saveMultiPageTIFFs:(NSButton *)sender{
    
    if(![self checkThereIsImageInScopeAndChannelsSelected:NO])
        return;
    
    if(self.inScopeImages.count > 1){
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.canChooseFiles = NO;
        panel.canChooseDirectories = YES;
        panel.canCreateDirectories = YES;
        [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
                for (IMCImageStack *stck in self.inScopeImages.copy) {
                    BOOL wasLoaded = stck.isLoaded;
                    if(!wasLoaded)
                        [stck loadLayerDataWithBlock:nil];
                    while (!wasLoaded);
                    [IMCFileExporter saveMultipageTiffAllChannels:stck path:[panel.URL.path stringByAppendingPathComponent:stck.fileWrapper.relativePath.lastPathComponent]];
                    if(!wasLoaded)
                        [stck unLoadLayerDataWithBlock:nil];
                }
        }];
    }else if(self.inScopeImages.count == 1){
        NSSavePanel * panel = [NSSavePanel savePanel];
        [self.inScopeImage.fileWrapper checkAndCreateWorkingFolder];
        panel.directoryURL = [NSURL fileURLWithPath:[self.inScopeImage.fileWrapper workingFolder]];
        [panel setNameFieldStringValue:[[self.inScopeImage.itemName stringByDeletingPathExtension]stringByAppendingString:@".tiff"]];
        [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
                [IMCFileExporter saveMultipageTiffAllChannels:self.inScopeImage path:panel.URL.path];
        }];
    }else{
    
    }
}
-(IBAction)saveMultiPageTIFFsWithSelected:(NSButton *)sender{
    if(![self checkThereIsImageInScopeAndChannelsSelected:YES])
        return;
    
    
    if(self.inScopeImages.count > 1){
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.canChooseFiles = NO;
        panel.canChooseDirectories = YES;
        panel.canCreateDirectories = YES;
        NSIndexSet *indexes = self.channels.selectedRowIndexes.copy;
        [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
                for (IMCImageStack *stck in self.inScopeImages.copy) {
                    BOOL wasLoaded = stck.isLoaded;
                    if(!wasLoaded)
                        [stck loadLayerDataWithBlock:nil];
                    while (!wasLoaded);
                    [IMCFileExporter saveMultipageTiffFromStack:stck forSelectedIndexes:indexes atDirPath:[panel URL].path fileName:nil];
                    if(!wasLoaded)
                        [stck unLoadLayerDataWithBlock:nil];
                }
        }];
    }else if(self.inScopeImages.count == 1){
        NSSavePanel * panel = [NSSavePanel savePanel];
        [self.inScopeImage.fileWrapper checkAndCreateWorkingFolder];
        panel.directoryURL = [NSURL fileURLWithPath:[self.inScopeImage.fileWrapper workingFolder]];
        [panel setNameFieldStringValue:[[self.inScopeImage.itemName stringByDeletingPathExtension]stringByAppendingString:@".tiff"]];
        [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
                [IMCFileExporter saveMultipageTiffFromStack:self.inScopeImage forSelectedIndexes:self.channels.selectedRowIndexes atDirPath:[panel URL].path.stringByDeletingLastPathComponent fileName:[panel URL].path.lastPathComponent];
        }];
    }else{
    
    }
}
-(IBAction)saveTIFFStackInFolder:(NSButton *)sender{
    if(![self checkThereIsImageInScopeAndChannelsSelected:NO])
        return;
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseFiles:NO];
    [panel setMessage:@"Select Location"];
    
    panel.directoryURL = [NSURL fileURLWithPath:[self.fileURL.path stringByDeletingLastPathComponent]];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSArray *ims = self.inScopeImages.copy;
            dispatch_queue_t saver = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
            dispatch_async(saver, ^{
                for (IMCImageStack *stck in ims) {
                    [stck openIfNecessaryAndPerformBlock:^{
                        NSString *folder = [IMCFileExporter saveTIFFsFolder:stck atFolderPath:panel.URL.path];
                        if(stck.pixelMasks.count > 0)
                            for (IMCPixelClassification *mask in stck.pixelMasks)
                                if(mask.isCellMask){
                                    NSString *maskPathCopy = [folder stringByAppendingPathComponent:[@"00" stringByAppendingString:mask.relativePath.lastPathComponent]];
                                    if(maskPathCopy){
                                        NSError *error;
                                        [[NSFileManager defaultManager]copyItemAtPath:mask.absolutePath toPath:maskPathCopy error:&error];
                                        if(error)
                                            NSLog(@"___Error %@", error);
                                    }
                                }
                    }];
                }
            });
        }
    }];

}

-(IBAction)saveCurrentView:(NSButton *)sender{
    [self saveCurrentAllOrZoomed:NO];
}
-(IBAction)saveCurrentVisible:(NSButton *)sender{
    [self saveCurrentAllOrZoomed:YES];
}
-(void)saveCurrentAllOrZoomed:(BOOL)zoomedIsYes{
    IMCScrollView *scr = [self inViewScrollView];
    if(scr && scr.imageView){
        
        NSSavePanel * panel = [NSSavePanel savePanel];
        [self.inScopeImage.fileWrapper checkAndCreateWorkingFolder];
        panel.directoryURL = [NSURL fileURLWithPath:[self.inScopeImage.fileWrapper workingFolder]];
        NSString *proposedName = [NSString stringWithFormat:@"%f.jpg", [NSDate timeIntervalSinceReferenceDate]];
        [panel setNameFieldStringValue:proposedName];
        [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton)
                [IMCFileExporter saveJPEGFromScroll:scr withPath:[panel URL].path allOrZoomed:zoomedIsYes];
        }];
    }
}

-(IBAction)saveCurrentViewToWorkingDirectory:(NSButton *)sender{
    [self saveCurrentVisibleViewToWorkingDirectoryZoomed:NO];
}
-(IBAction)saveCurrentVisibleViewToWorkingDirectory:(NSButton *)sender{
    [self saveCurrentVisibleViewToWorkingDirectoryZoomed:YES];
}
-(void)saveCurrentVisibleViewToWorkingDirectoryZoomed:(BOOL)zoomed{
    IMCScrollView *scr = [self inViewScrollView];
    if(scr && scr.imageView){
        [self.dataCoordinator checkAndCreateWorkingDirectory];
        NSString *path = [[self.dataCoordinator workingDirectoryPath]stringByAppendingPathComponent:[NSString stringWithFormat:@"/%f.jpg", [NSDate timeIntervalSinceReferenceDate]]];
        [IMCFileExporter saveJPEGFromScroll:scr withPath:path allOrZoomed:zoomed];
    }
}
//TODO find active view
-(IBAction)copy:(id)sender{
    NSString *ident = self.tabs.selectedTabViewItem.identifier;
    if([ident isEqualToString:TAB_ID_THREED]){
        NSImage *im = [self.metalView getImageBitMapFromRect:self.metalView.bounds];
        NSImage *im2 = [NSImage imageWithRef:[self.metalView captureImageRef]];
        NSImage *merge = [IMCFileExporter mergeImage:im2 andB:im fraction:1.0f];
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[merge]];
    }
    else
        [IMCFileExporter copyToClipBoardFromScroll:[self inViewScrollView] allOrZoomed:NO];
}
-(IBAction)copy3Dpic:(id)sender{
    NSImage *im;
    if(self.openGlViewPort)
        im = [self.openGlViewPort imageFromViewOld];
    else
        im = [NSImage imageWithRef:[self.metalView captureImageRef]];
    
    if(im){
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[im]];
    }
}
-(IBAction)copyCurrentVisible:(NSButton *)sender{
    [IMCFileExporter copyToClipBoardFromScroll:[self inViewScrollView] allOrZoomed:YES];
}
-(IBAction)copyLegend:(NSButton *)sender{
    [IMCFileExporter copyToClipBoardFromView:self.colorLegend];
}

#pragma mark Export Data
typedef enum {
    TableExportTypeTSV,
    TableExportTypeFCS,
    TableExportTypeBinary
} TableExportType;

-(void)generalExportCellDataTable:(TableExportType)type{
    if(self.whichTableCoordinator.indexOfSelectedItem != 5 && self.whichTableCoordinator.indexOfSelectedItem != 7)
        return;
    
    NSIndexSet *setMetadata = [IMCUtils inputTable:self.dataCoordinator.metadata[JSON_METADATA_KEYS] prompt:@"Do you want to stich metadata? Select which fields to add"];
    
    NSSavePanel * panel = [NSSavePanel savePanel];
    NSString *proposedName = [NSString stringWithFormat:@"%f.", [NSDate timeIntervalSinceReferenceDate]];
    if (type == TableExportTypeTSV) proposedName = [proposedName stringByAppendingString:@"tsv"];
    if (type == TableExportTypeFCS) proposedName = [proposedName stringByAppendingString:@"fcs"];
    if (type == TableExportTypeBinary) proposedName = [proposedName stringByAppendingString:@"hcat"];
    
    [panel setNameFieldStringValue:proposedName];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            if (type == TableExportTypeTSV)
                [IMCFileExporter saveCSVWithComputations:self.inScope3DMask ? @[self.inScope3DMask] : self.inScopeComputations atPath:panel.URL.path columnIndexes:self.channels.selectedRowIndexes dataCoordinator:self.dataCoordinator metadataIndexes:setMetadata];
            if (type == TableExportTypeFCS)
                [IMCFileExporter saveCSVWithComputations:self.inScope3DMask ? @[self.inScope3DMask] : self.inScopeComputations atPath:panel.URL.path columnIndexes:self.channels.selectedRowIndexes dataCoordinator:self.dataCoordinator metadataIndexes:setMetadata];
            if (type == TableExportTypeBinary)
                [IMCFileExporter saveBinaryWithComputations:self.inScope3DMask ? @[self.inScope3DMask] : self.inScopeComputations atPath:panel.URL.path columnIndexes:self.channels.selectedRowIndexes dataCoordinator:self.dataCoordinator metadataIndexes:setMetadata];
        }
        
    }];
}
-(IBAction)exportCSV:(id)sender{
    [self generalExportCellDataTable:TableExportTypeTSV];
}
-(IBAction)exportFCS:(id)sender{
    [self generalExportCellDataTable:TableExportTypeFCS];
}
-(IBAction)exportBinary:(id)sender{
    [self generalExportCellDataTable:TableExportTypeBinary];
}

#pragma mark metadata

-(NSString *)getMetadataKeyFromUser{
    NSString *newKey = [IMCUtils input:@"New metadata key" defaultValue:@"NewKey"];
    if(newKey){
        NSMutableArray *keys = self.dataCoordinator.metadata[JSON_METADATA_KEYS];
        int counter = 1;
        while ([keys containsObject:newKey]){
            newKey = [[newKey componentsSeparatedByString:@"_"].firstObject stringByAppendingFormat:@"_%i", counter];
            counter++;
        }
        if(keys.count > 0)
            [keys insertObject:newKey atIndex:0];
        else
            [keys addObject:newKey];
    }
    return newKey;
}

-(void)addMetadataLabel:(id)sender{
    NSString *newKey = [self getMetadataKeyFromUser];
    if(!newKey)
        [General runAlertModalWithMessage:@"Please give a valid name"];
    else
        [self.metadataTableDelegate rebuildTable];
}

-(void)removeMetadataLabel:(id)sender{
    NSInteger sure = [General runAlertModalAreYouSure];
    if (sure == NSAlertSecondButtonReturn)return;
    
    if(self.metadataTable.selectedColumn != NSNotFound){
        [self.dataCoordinator.metadata[JSON_METADATA_KEYS] removeObjectAtIndex:self.metadataTable.selectedColumn - METADATA_GIVEN_COLUMNS_OFFSET];
        [self.metadataTableDelegate rebuildTable];
    }
}
-(void)renameMetadataLabel:(id)sender{
    if(self.metadataTable.selectedColumn != NSNotFound){
        NSMutableArray *keys = self.dataCoordinator.metadata[JSON_METADATA_KEYS];
        NSString *oldKey = [keys[self.metadataTable.selectedColumn - METADATA_GIVEN_COLUMNS_OFFSET]copy];
        NSString *newKey = [IMCUtils input:@"Rename metadata key" defaultValue:oldKey.copy];
        if(![keys containsObject:newKey] && newKey){
            for(IMCImageStack *stack in self.dataCoordinator.inOrderImageWrappers){
                NSMutableDictionary *dict = [self.dataCoordinator metadataForImageStack:stack];
                id oldObj = dict[oldKey];
                dict[oldKey] = nil;
                dict[newKey] = oldObj;
            }
            [keys replaceObjectAtIndex:self.metadataTable.selectedColumn - METADATA_GIVEN_COLUMNS_OFFSET withObject:newKey];
        }
        [self.metadataTableDelegate rebuildTable];
    }
}
-(void)applySelectionBackwards:(id)sender{
    NSArray *metadataTableSelectedItems = [self.metadataTableDelegate selectedStacks];
    //[self.filesTree deselectAll:nil];
    NSMutableIndexSet *is = [[NSMutableIndexSet alloc]init];
    NSLog(@"+");
    [self.filesTree.selectedRowIndexes.copy enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        IMCNodeWrapper *node  = [self.filesTree itemAtRow:idx];
        while(node.parent){
            if([metadataTableSelectedItems containsObject:node]){
                [is addIndex:idx];
                break;
            }
            node = node.parent;
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.filesTree selectRowIndexes:is byExtendingSelection:NO];
    });
    [self.metadataTable selectAll:nil];
}
-(void)exportMetadataTSV:(id)sender{
    NSSavePanel * panel = [NSSavePanel savePanel];
    NSString *proposedName = [NSString stringWithFormat:@"%f.tsv", [NSDate timeIntervalSinceReferenceDate]];
    [panel setNameFieldStringValue:proposedName];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
            [IMCFileExporter saveTSVWithMetadata:self.involvedStacksForMetadata atPath:panel.URL.path withCoordinator:self.dataCoordinator];
    }];
}

#pragma mark calculations to be added to metadata

#define METRIC_TOTAL @"Total"
#define METRIC_AVERAGE @"Average"
#define METRIC_MEDIAN @"Median"
#define METRIC_STDD @"Standard Deviation"
#define METRIC_COUNTS @"Counts"
#define METRIC_PROPORTION @"Proportion"
#define METRIC_SHANNON @"Shannon Index"
#define METRIC_SIMPSON @"Simpson Index"
#define METRIC_AVERAGED_SOSQ @"Averaged Sum of Squares"

-(void)calcToMetadata:(NSMenuItem *)item{
    NSString *key = [self getMetadataKeyFromUser];
    if(key){
        NSMutableArray *metrics = @[METRIC_COUNTS].mutableCopy;
        NSInteger channelsSelected = self.channels.selectedRowIndexes.count;
        if(channelsSelected == 1){
            [metrics addObjectsFromArray:@[METRIC_TOTAL, METRIC_AVERAGE, METRIC_MEDIAN, METRIC_STDD]];
        }else{
            switch (channelsSelected) {
                case 2:
                    [metrics addObject:METRIC_PROPORTION];
                    
                default:
                {
                    if(!VIEWER_HISTO && !VIEWER_ONLY)
                    [metrics addObjectsFromArray:@[
                                                   METRIC_SHANNON,
                                                   METRIC_SIMPSON,
                                                   ]];
                    
                    [metrics addObject:METRIC_AVERAGED_SOSQ];
                }
                    break;
            }
        }
        NSInteger selected = [IMCUtils inputOptions:metrics prompt:@"Select a metric"];
        NSString *metricSelected = metrics[selected];
        
        NSIndexSet *indexes = self.channels.selectedRowIndexes.copy;
        NSString *chan1 = self.inScopeComputation.channels[self.channels.selectedRowIndexes.firstIndex];
        NSString *chan2 = self.inScopeComputation.channels[self.channels.selectedRowIndexes.lastIndex];
        NSInteger choiceProp = 0;
        if([metricSelected isEqualToString:METRIC_PROPORTION]){
            NSString * aToB = [NSString stringWithFormat:@"%@ / %@", chan1, chan2];
            NSString * bToA = [NSString stringWithFormat:@"%@ / %@", chan2, chan1];
            choiceProp = [IMCUtils inputOptions:@[aToB, bToA] prompt:@"Select ratio"];
            
        }
        __block float result = -1.0f;
        
        NSArray *comps = self.inScopeComputations.copy;
        
        dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
        dispatch_async(aQ, ^{
            
            for (IMCComputationOnMask *comp in comps) {
                
                BOOL wasLoaded = comp.isLoaded;
                while (!comp.isLoaded)
                    [comp loadLayerDataWithBlock:nil];
                
                NSArray *channArrays = [comp arrayOfChannelArrays:indexes];
                if([metricSelected isEqualToString:METRIC_COUNTS]){
                    NSInteger counts = .0f;
                    for (NSArray *arrNumbers in channArrays)
                        counts += [arrNumbers count];
                    result = (float)counts;
                }
                if([metricSelected isEqualToString:METRIC_SHANNON]){
                    NSArray *summary = [comp countStatsForStack:indexes];
                    result = summary.shannonIndex;
                }
                if([metricSelected isEqualToString:METRIC_SIMPSON]){
                    NSArray *summary = [comp countStatsForStack:indexes];
                    result = summary.simpsonIndex;
                }
                if([metricSelected isEqualToString:METRIC_AVERAGED_SOSQ])
                    result = [comp averagedSumOfSquaresForArray:channArrays];
                
                if([metricSelected isEqualToString:METRIC_TOTAL])
                    result = [[comp totalForChannelArray:channArrays.firstObject]floatValue];
                
                if([metricSelected isEqualToString:METRIC_AVERAGE])
                    result = [[comp meanForChannelArray:channArrays.firstObject]floatValue];
                
                if([metricSelected isEqualToString:METRIC_MEDIAN])
                    result = [[comp modeForChannelArray:channArrays.firstObject]floatValue];
                
                if([metricSelected isEqualToString:METRIC_STDD])
                    result = [[comp stddForChannelArray:channArrays.firstObject]floatValue];
                
                if([metricSelected isEqualToString:METRIC_PROPORTION]){
                    if(choiceProp == 0 && [channArrays.lastObject count] > 0)
                        result = [channArrays.firstObject count]/(float)[channArrays.lastObject count];
                    if(choiceProp == 1 && [channArrays.firstObject count] > 0)
                        result = [channArrays.lastObject count]/(float)[channArrays.firstObject count];
                }
                
                NSMutableDictionary *dict = [self.dataCoordinator metadataForImageStack:comp.mask.imageStack];
                dict[key] = [NSString stringWithFormat:@"%f", result];
                if(!wasLoaded)
                    [comp unLoadLayerDataWithBlock:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.metadataTable reloadData];
                });
            }
        });
    }
}

#pragma mark scrollview in view

-(IMCScrollView *)inViewScrollView{
    IMCScrollView *which;
    NSString *ident = self.tabs.selectedTabViewItem.identifier;
    if([ident isEqualToString:TAB_ID_BLEND])which = self.scrollViewBlends;
    if([ident isEqualToString:TAB_ID_TILES])which = self.scrollViewTiles;
    if([ident isEqualToString:TAB_ID_PLOTS])which = self.plotResult;
    return which;
}

#pragma mark Outline View DataSource


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    return [self.workSpaceHandler outlineView:outlineView isItemExpandable:item];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    return [self.workSpaceHandler outlineView:outlineView numberOfChildrenOfItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    return [self.workSpaceHandler outlineView:outlineView child:index ofItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item{
    return [self.workSpaceHandler outlineView:outlineView objectValueForTableColumn:theColumn byItem:item];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification{
    [self.workSpaceHandler outlineViewSelectionDidChange:notification];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    [self.workSpaceHandler outlineView:outlineView willDisplayCell:cell forTableColumn:tableColumn item:item];
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    return [self.workSpaceHandler outlineView:outlineView shouldEditTableColumn:tableColumn item:item];
}
-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    [self.workSpaceHandler outlineView:outlineView setObjectValue:object forTableColumn:tableColumn byItem:item];
}
#pragma mark tableView

-(IBAction)updateTableView:(NSSegmentedControl *)sender{
    [self.workSpaceHandler updateTableView:sender];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.workSpaceHandler numberOfRowsInTableView:tableView];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return [self.workSpaceHandler tableView:tableView objectValueForTableColumn:tableColumn row:row];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    return [self.workSpaceHandler tableViewSelectionDidChange:notification];
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    [self.workSpaceHandler tableView:tableView willDisplayCell:cell forTableColumn:tableColumn row:row];
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    [self.workSpaceHandler tableView:tableView setObjectValue:object forTableColumn:tableColumn row:row];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return [self.workSpaceHandler tableView:tableView shouldEditTableColumn:tableColumn row:row];
}

#pragma mark external tableview delegates

-(NSArray *)channelsForCell{
    if(self.inScopeComputations.count > 0)
        return self.inScopeComputation.channels;
    else if(self.inScope3DMask)
        return self.inScope3DMask.channels;
    else
        return self.inScopeImage.channels;
}

-(NSArray *)indexesForCell{
    return [NSArray arrayWithArray:self.inOrderIndexes];
}
-(void)didChangeChannel:(NSDictionary *)channelSettings{
    [self refresh];
}
-(NSInteger)typeOfColoring{
    return self.colorSpaceSelector.selectedSegment;
}

-(NSTableView *)whichTableView{
    return self.channelsCustom;
}
-(NSArray <IMCComputationOnMask *>*)computations{
    if(self.inScope3DMask)
        return @[self.inScope3DMask];
    return self.inScopeComputations;
}
-(NSArray <IMCImageStack *>*)stacks{
    return self.inScopeImages;
}
-(NSTableView *)tableViewEvents{
    return self.eventsTable;
}
-(void)changed:(NSInteger)oldChannel for:(NSInteger)newChannel{
    [self.channels deselectRow:oldChannel];
    if(![self.channels.selectedRowIndexes containsIndex:newChannel])
        [self.channels selectRowIndexes:[NSIndexSet indexSetWithIndex:newChannel] byExtendingSelection:YES];
}
#pragma mark NSTabView

-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem{
    if(self.inScope3DMask)
        self.scrollViewBlends.imageView.selectedArea = NSRectFromString(self.inScope3DMask.roiMask);
    self.threeDHandler.interestProportions = self.scrollViewBlends.imageView.selectedArea;
    [self refresh];
}

#pragma mark Contextual menus

-(NSMenu *)tableView:(NSTableView *)aTableView menuForRows:(NSIndexSet *)rows{
    return [self.workSpaceHandler tableView:aTableView menuForRows:rows];
}
-(NSArray *)selectedNodes{
    NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:self.filesTree.selectedRowIndexes.count];
    [self.filesTree.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){[nodes addObject:[self.filesTree itemAtRow:index]];}];
    return nodes;
}
-(void)openNodes:(NSMenuItem *)sender{
    NSArray *nodes = [self selectedNodes];
    dispatch_queue_t loader = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(loader, ^{
        __block NSInteger counter = 0;
        for (IMCNodeWrapper *node in nodes) {
            counter++;
            while(counter>4);
            [node loadLayerDataWithBlock:^{counter--;}];
        }
        [self refresh];
    });
}
-(void)closeNodes:(NSMenuItem *)sender{
    for (IMCNodeWrapper *node in [self selectedNodes])
        if(node.isLoaded)
            [node unLoadLayerDataWithBlock:^{[self refresh];}];
}
-(void)removeFiles:(NSMenuItem *)sender{
    for (IMCFileWrapper *wrapper in self.inScopeFiles.copy){
        [self.dataCoordinator.filesJSONDictionary removeObjectForKey:wrapper.fileHash];
        if([wrapper isLoaded])
            [wrapper unLoadLayerDataWithBlock:^{
                if(self.inScopeImage.parent.parent == wrapper)
                    self.inScopeImage = nil;
            }];
        [self.dataCoordinator removeFileWrapper:wrapper];
        [self refresh];
    }
}
-(void)reloadPanoramas:(NSMenuItem *)sender{
    [General runAlertModalWithMessage:@"TODO. Reload panoramas in case of working with TIFF copy"];
}
-(void)tiffConvert:(NSMenuItem *)sender{
    [IMCChannelOperations converttoTIFFFiles:self.inScopeFiles block:^{[self refresh];}];
}
-(void)saveFiles:(NSMenuItem *)sender{
    [IMCChannelOperations savefiles:self.inScopeFiles block:^{[self refresh];}];
}

-(void)deleteChannels:(NSMenuItem *)sender{
    NSIndexSet *is = self.channels.selectedRowIndexes.copy;
    
    self.channels.delegate = nil;

    if(self.inScopeImages.count > 0)
        [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_REMOVE_CHANNELS withIndexSetChannels:is toIndex:-1 block:^{[self refresh];}];//Index irrelevant
    if(self.inScopeComputations.count > 0)
        [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_REMOVE_CHANNELS withIndexSetChannels:is toIndex:-1 block:^{[self refresh];}];
    if(self.inScope3DMasks.count > 0)
        [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_REMOVE_CHANNELS withIndexSetChannels:is toIndex:-1 block:^{[self refresh];}];
    
    self.channels.delegate = self;
}
-(void)addChannelsInline:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
}
-(void)addChannelsBeggining:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];//Index irrelevant
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];//Index irrelevant
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];//Index irrelevant
}
-(void)addChannelsEnd:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScopeImage.channels.count block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScopeComputation.channels.count block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_ADD_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScope3DMask.channels.count block:^{[self refresh];}];
}
-(void)multiplyChannelsInline:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.channels.selectedRow + 1 block:^{[self refresh];}];
}
-(void)multiplyChannelsBeggining:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:0 block:^{[self refresh];}];
}
-(void)multiplyChannelsEnd:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations operationOnImages:self.inScopeImages.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScopeImage.channels.count block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScopeComputations.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScopeComputation.channels.count block:^{[self refresh];}];
    [IMCChannelOperations operationOnComputations:self.inScope3DMasks.copy operation:OPERATION_MULTIPLY_CHANNELS withIndexSetChannels:selectedChannels toIndex:self.inScope3DMask.channels.count block:^{[self refresh];}];
}
-(void)applySettings:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    if(self.inScopeImage)
        [IMCChannelOperations applySettingsFromStack:self.inScopeImage stacks:self.inScopeImages.copy withIndexSetChannels:selectedChannels block:^{
            [self refresh];
        }];
    if(self.inScopeComputation)
        [IMCChannelOperations applySettingsFromComputation:self.inScopeComputation stacks:self.inScopeComputations withIndexSetChannels:selectedChannels block:^{
            [self refresh];
        }];
}
-(void)applySettingsWithMax:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations applySettingsAdjustToMaxFromStack:self.inScopeImage stacks:self.inScopeImages.copy withIndexSetChannels:selectedChannels block:^{
        [self refresh];
    }];
}
-(void)applyColors:(NSMenuItem *)sender{
    NSIndexSet *selectedChannels = self.channels.selectedRowIndexes.copy;
    [IMCChannelOperations applyColors:self.inScopeImage stacks:self.inScopeImages.copy withIndexSetChannels:selectedChannels block:^{
        [self refresh];
    }];
}
-(void)importMaskNuclear:(BOOL)nuclear{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            if (nuclear)
                [self.inScopeMask getNuclearMaskAtURL:[[panel URLs]firstObject]];
            else
                [self.inScopeImage getMaskAtURL:[[panel URLs]firstObject]];
        }
    }];
    
}
-(void)importMask:(NSMenuItem *)sender{
    [self importMaskNuclear:NO];
}
-(void)importNuclearMask:(NSMenuItem *)sender{
    [self importMaskNuclear:YES];
    
}
-(void)loadMask:(NSMenuItem *)sender{
    id item = [self.filesTree itemAtRow:self.filesTree.selectedRow];
    if([item isMemberOfClass:[IMCPixelClassification class]])
        [(IMCPixelClassification *)item loadMask];
}
//-(void)removeTraining:(NSMenuItem *)sender{
//    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
//    id item = [self.filesTree itemAtRow:self.filesTree.selectedRow];
//    if([item isMemberOfClass:[IMCPixelTraining class]]){
//        IMCPixelTraining *train = item;
//        [train.imageStack removeChild:train];
//    }
//    [self refresh];
//}
-(void)removeNodes:(NSMenuItem *)sender{
    NSInteger sure = [General runAlertModalAreYouSure];if (sure == NSAlertSecondButtonReturn)return;
    [self.filesTree.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        id item = [self.filesTree itemAtRow:idx];
        if([item isMemberOfClass:[IMCPixelTraining class]]){
            IMCPixelTraining *train = item;//I use train
            [train.imageStack removeChild:train];
        }
        if([item isMemberOfClass:[IMCPixelMap class]]){
            IMCPixelMap *map = item;//I use train
            [map.imageStack removeChild:map];
        }
        if([item isMemberOfClass:[IMCPixelClassification class]]){
            IMCPixelClassification *mask = item;//I use train
            [mask.imageStack removeChild:mask];
            [self.involvedStacksForMetadata removeObject:mask.imageStack];
        }
        if([item isMemberOfClass:[IMCComputationOnMask class]]){
            IMCComputationOnMask *comp = item;//I use train
            [comp.mask removeChild:comp];
            [self.involvedStacksForMetadata removeObject:comp];
        }
//        if([item isMemberOfClass:[IMCMaskTraining class]]){
//            IMCPixelTraining *train = item;//I use train
//            [train.imageStack removeChild:train];
//        }
        if([item isMemberOfClass:[IMC3DMask class]]){
            IMC3DMask *comp = item;//I use train
            [comp deleteSelf];
        }
    }];
    [self refresh];
}
-(void)addFeaturesFromCP:(NSMenuItem *)sender{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            id item = [self.filesTree itemAtRow:self.filesTree.selectedRow];
            if([item isMemberOfClass:[IMCComputationOnMask class]])
                [(IMCComputationOnMask *)item addFeaturesFromCellProfiler:[[panel URLs]firstObject]];
            else
                [self.inScopeMask addFeaturesFromCellProfiler:[[panel URLs]firstObject]];
        }
    }];
}
-(void)distances3D:(NSMenuItem *)sender{
    if(self.inScope3DMask){
        NSMutableArray * possibles = @[].mutableCopy;
        NSMutableArray * names = @[].mutableCopy;
        for (IMC3DMask *other in self.dataCoordinator.threeDNodes) {
            if(other != self.inScope3DMask){
                [possibles addObject:other];
                [names addObject:other.itemName];
            }
        }
        NSInteger chosen = [IMCUtils inputOptions:names prompt:@"Select a destination mask for distance calculation"];
        if(chosen != NSNotFound){
            IMC3DMask * chosenMask = possibles[chosen];
            if(chosenMask){
                [self.inScope3DMask distanceToOtherMaskEuclidean:chosenMask];
            }
        }
    }
}
-(void)clusterInteraction:(NSMenuItem *)sender{
    if(self.inScope3DMask){
        NSInteger chosen = [IMCUtils inputOptions:self.inScope3DMask.channels prompt:@"Select a categorical variable (e.g. Flock clustering)"];
        if(chosen != NSNotFound){
            NSArray *adjMatrix = [self.inScope3DMask generateAdjacencyMatrix];
            float * summary = [self.inScope3DMask summaryOfAdjacencyMatrixUsingCategoricalVariable:chosen forAdjacencyMatrix:adjMatrix];
            float * expected = [self.inScope3DMask expectedMatrixWithSummary:summary forAdjacencyMatrix:adjMatrix categoricalVariable:chosen];
            float * observed = [self.inScope3DMask observedMatrixWithSummary:summary forAdjacencyMatrix:adjMatrix categoricalVariable:chosen];
            printf("%p %p", expected, observed);
            //[self.inScope3DMask interactionAnalysis:chosen];
        }
    }
}
-(void)duplicate3DMask:(NSMenuItem *)sender{
    if(self.inScope3DMask)
        [self.inScope3DMask copyThisMask];
}

-(void)convertToMask:(NSMenuItem *)sender{

}
-(void)extractFeaturesForMask:(NSMenuItem *)sender{
    
    NSInteger rawOrProcessedData = [IMCUtils inputOptions:@[@"Extract from raw pixel data", @"Extract from preprocessed data"] prompt:@"Choose an option"];
    if(rawOrProcessedData >= 0){
        NSIndexSet *computations = [General cellComputations];
        __block NSInteger counter = 0;
        NSArray *masks = self.inScopeMasks.copy;
        
        dispatch_queue_t feat = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
        dispatch_async(feat, ^{
            for(IMCPixelClassification *mask in masks){
                while (counter>3);
                counter++;
                [mask openIfNecessaryAndPerformBlock:^{
                    [mask extractDataForMask:computations processedData:(BOOL)rawOrProcessedData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        counter--;
                        [self.filesTree reloadData];
                    });
                }];
            }
        });
    }
}
-(void)addChannelsFromTSV:(NSMenuItem *)sender{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton)
            [IMCChannelOperations changeChannelsToStacks:self.inScopeImages withFile:panel.URLs.firstObject block:^{
                [self refresh];
            }];
    }];
}
-(void)copyJsonForNode:(NSMenuItem *)sender{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    IMCNodeWrapper *node = [self.filesTree itemAtRow:self.filesTree.selectedRow];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:node.jsonDictionary options:NSJSONWritingPrettyPrinted error:NULL];
    [pasteboard setString:[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding] forType:NSStringPboardType];
}
-(void)editThresholdMask:(NSMenuItem *)sender{
    IMCPixelClassification * item = [self.filesTree itemAtRow:self.filesTree.selectedRow];
    if([item isMemberOfClass:[IMCPixelClassification class]])
        if([item isThreshold]){
            IMCThresholdMask *seg = [[IMCThresholdMask alloc]initWithStack:item.imageStack andMask:item];
            [[seg window] makeKeyAndOrderFront:seg];
        }
}
-(void)editPaintedMask:(NSMenuItem *)sender{
    IMCPixelClassification * item = [self.filesTree itemAtRow:self.filesTree.selectedRow];
    if([item isMemberOfClass:[IMCPixelClassification class]])
        if([item isPainted]){
            IMCPaintMask *seg = [[IMCPaintMask alloc]initWithStack:item.imageStack andMask:item];
            [[seg window] makeKeyAndOrderFront:seg];
        }
}
#pragma mark Refresh
-(void)changedWhiteBackground:(NSButton *)sender{
    [self.multiImageFilters selectItemAtIndex:self.brightFieldEffect.state == NSOnState?1:2];
    [self refresh];
}
-(void)calculateMemory{
    [self.workSpaceRefresher calculateMemory];
}
-(void)refresh:(id)sender{
    if(sender == self.gaussianBlur)
        self.gaussianBlurLabel.intValue = self.gaussianBlur.intValue;
    [self refresh];
}

-(void)refresh{
    if(self.compensationSession)
        [NSApp endModalSession:self.compensationSession];
    self.compensationSession = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.workSpaceRefresher refresh];
        if([self.tabs.selectedTabViewItem.label isEqualToString:TAB_ID_THREED]){
            self.metalViewDelegate.forceColorBufferRecalculation = YES;
        }
    });
}

-(void)refreshBlend{
    [self.workSpaceRefresher refreshBlend];
}

-(void)refreshTiles{
    [self.workSpaceRefresher refreshTiles];
}

-(void)refreshFromImageArray:(NSMutableArray *)array{
    if(array.count == 0)return;
    self.scrollViewBlends.imageView.image = array.firstObject;
    [self.scrollViewTiles assembleTiledWithImages:array];
}
#pragma mark queries on tables

-(void)searchTable:(NSTextField *)sender{
    if(sender == self.searchTree){
        self.dataCoordinator.treeSearch = sender.stringValue;
        [self.filesTree reloadData];
    }
    if(sender == self.searchChannels){
        NSArray *channels;
        NSArray *origChannels;
        if(self.inScopeComputation){
            channels = self.inScopeComputation.channels;
            origChannels = self.inScopeComputation.originalChannels;
        }
        if(self.inScopeImage){
            channels = self.inScopeImage.channels;
            origChannels = self.inScopeImage.origChannels;
        }
        NSString *needle = self.searchChannels.stringValue.lowercaseString;
        if(channels && origChannels && needle.length > 0){
            NSInteger firstSelected = self.channels.selectedRowIndexes.lastIndex;
            NSMutableIndexSet *is = [[NSMutableIndexSet alloc]init];
            for (NSInteger i = 0; i < channels.count; i++) {
                if([[channels[i]lowercaseString] rangeOfString:needle.lowercaseString].location != NSNotFound ||
                   [[origChannels[i]lowercaseString] rangeOfString:needle].location != NSNotFound)
                    [is addIndex:i];
            }
            NSInteger larg = [is indexGreaterThanIndex:firstSelected];
            if(larg == NSNotFound)
                larg = is.firstIndex;
            [self.channels selectRowIndexes:[NSIndexSet indexSetWithIndex:larg] byExtendingSelection:YES];
            [self.channels scrollRowToVisible:larg];
        }
    }
}

#pragma mark scrolling control
-(IBAction)changedPanelScrollingType:(NSPopUpButton *)sender{
    [self.workSpaceRefresher changedPanelScrollingType:sender];
}

#pragma mark get values at position

-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll{
    NSPoint event_location = [event locationInWindow];
    NSPoint processed = [self.scrollViewBlends.imageView convertPoint:event_location fromView:nil];

    NSPoint ori = [self.scrollViewBlends.imageView yFlippedtopOriginOfContainedImage];
    processed.x -= ori.x;
    processed.y -= ori.y;
    processed = [self.scrollViewBlends getTranslatedPoint:processed];
    
    if(self.applyTransfomrs.indexOfSelectedItem == 0){
        IMCImageStack *stack = self.inScopeImage;
        if(!stack)stack = self.inScopeMask.imageStack;
        if(!stack)stack = self.inScopeComputation.mask.imageStack;
        NSInteger index = floorf(processed.y) * stack.width + round(processed.x);
        if(index >= 0 && index < stack.numberOfPixels){
            if(self.inOrderIndexes.count == 1){
                if(self.inScopeImages.count == 1 && self.inScopeImage.isLoaded)
                    if(index >= 0 && index < self.inScopeImage.numberOfPixels)
                        self.sizeImage.stringValue = [NSString stringWithFormat:@"%.2f", self.inScopeImage.stackData[self.channels.selectedRow][index]];
                if(self.inScopeComputations.count == 1 && self.inScopeComputation.isLoaded)
                    self.sizeImage.stringValue = [NSString stringWithFormat:@"%.2f", self.inScopeComputation.computedData[self.channels.selectedRow][abs(self.inScopeComputation.mask.mask[index]) - 1]];
            }
            if(self.inScopeMasks.count == 1 && self.inScopeMask.isLoaded)
                self.sizeImage.stringValue = [NSString stringWithFormat:@"%i", self.inScopeMask.mask[index]];
        }
    }
}
-(void)mouseUpCallback:(NSEvent *)event{
    [self.workSpaceRefresher updateForWithStack:self.inScopeImage];
}

#pragma mark 3D alignment
-(NSArray *)involvedStacks{
    NSMutableArray *involvedStacks = [self.inScopeImages mutableCopy];
    for (IMCPixelClassification *mask in self.inScopeMasks) {
        if(![involvedStacks containsObject:mask.imageStack])
            [involvedStacks addObject:mask.imageStack];
    }
    for (IMCComputationOnMask *comp in self.inScopeComputations) {
        if(![involvedStacks containsObject:comp.mask.imageStack])
            [involvedStacks addObject:comp.mask.imageStack];
    }
    return involvedStacks;
}
-(void)rotate:(float)rotation andTranslate:(float)x y:(float)y{
    NSArray *involvedStacks = [self involvedStacks];
    if(involvedStacks.count == 2 && self.channels.selectedRowIndexes.count < 3){
        IMCImageStack *stack = self.inScopeImage;//involvedStacks.lastObject;
        if(!stack)
            stack = self.inScopeMask.imageStack;
        if(!stack)
            stack = self.inScopeComputation.mask.imageStack;
        if(!stack)
            return;
        
        float rotateCalc = rotation * .003f * pow(10, self.transformDictController.coarseValue.selectedSegment);
        float xCalc = x * .01f * pow(10, self.transformDictController.coarseValue.selectedSegment);
        float yCalc = y * .01f * pow(10, self.transformDictController.coarseValue.selectedSegment);
        
        [stack rotate:rotateCalc andTranslate:xCalc y:yCalc];
        if(self.pegAligns.state == NSOnState){
            NSArray *arr = [self.dataCoordinator inOrderImageWrappers];
            NSInteger thisIndex = [arr indexOfObject:stack];
            for (NSInteger i = thisIndex + 1; i < arr.count; i++) {
                IMCImageStack *next = arr[i];
                [next rotate:rotateCalc andTranslate:xCalc y:yCalc];
            }
        }
        
//        float prevRot = [stack.transform[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue];
//        float prevX = [stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue];
//        float prevY = [stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue];
//        
//        [stack.transform setValue:
//         [NSNumber numberWithFloat:prevRot + rotation * .003f * pow(10, self.transformDictController.coarseValue.selectedSegment)]
//                           forKey:JSON_DICT_IMAGE_TRANSFORM_ROTATION];
//        [stack.transform setValue:
//         [NSNumber numberWithFloat:prevX + x * .01f * pow(10, self.transformDictController.coarseValue.selectedSegment)]
//                           forKey:JSON_DICT_IMAGE_TRANSFORM_OFFSET_X];
//        [stack.transform setValue:
//         [NSNumber numberWithFloat:prevY - y * .01f * pow(10, self.transformDictController.coarseValue.selectedSegment)]
//                           forKey:JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y];
        
        [self.transformDictController updateFromDict];
        [self refresh];
    }
}
-(void)rotated:(float)rotation{
    [self rotate:rotation andTranslate:.0f y:.0f];
}
-(void)translated:(NSEvent *)eventTrans{
    float deltaX = eventTrans.deltaX;
    float deltaY = eventTrans.deltaY;
    [self rotate:.0f andTranslate:deltaX y:deltaY];
}
-(void)alignSelected:(NSButton *)sender{
    sender.enabled = NO;
//    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
//    dispatch_async(aQ, ^{
        [self.workSpaceRefresher alignSelected];
//        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
//        });
//    });
}
#pragma mark 3D reconstruction
-(BOOL)canRender{
    NSInteger tab = self.whichTableCoordinator.indexOfSelectedItem;
    if(tab != 1 && tab !=5 && tab !=7){
        [General runAlertModalWithMessage:@"You can render only from the stacks, measurements, or 3d Masks views"];
        return NO;
    }
    if(self.filesTree.selectedRowIndexes.count == 0 || self.channels.selectedRowIndexes.count == 0){
        [General runAlertModalWithMessage:@"Select slices and channels"];
        return NO;
    }
    return YES;
}
-(void)stepperZChanged:(id)sender{
    self.labelStepperDefaultZ.stringValue = [NSString stringWithFormat:@"%.2f", self.stepperDefaultZ.floatValue];
    self.threeDHandler.defaultZ = self.stepperDefaultZ.floatValue;
}
-(void)typeOf3DMesh:(NSPopUpButton *)sender{
    self.cellModifier.hidden = sender.indexOfSelectedItem == 0;
    if(sender.indexOfSelectedItem == 0)self.metalView.delegate = self.metalViewDelegate;
    if(sender.indexOfSelectedItem == 1)self.metalView.delegate = self.sphereMetalViewDelegate;
    if(sender.indexOfSelectedItem == 2)self.metalView.delegate = self.stripedSphereMetalViewDelegate;
    if(sender.indexOfSelectedItem == 3){
        //TODO
        [sender selectItemAtIndex:0];
        self.metalView.delegate = self.metalViewDelegate;
        [General runAlertModalWithMessage:@"Funcion not yet implemented, reset to voxels"];
        
    }
    self.metalViewDelegate.forceColorBufferRecalculation = YES;
    self.sphereMetalViewDelegate.forceColorBufferRecalculation = YES;
    self.stripedSphereMetalViewDelegate.forceColorBufferRecalculation = YES;
}
-(void)start3Dreconstruction:(NSButton *)sender{
    if([self canRender]){
        sender.enabled = NO;
        
        NSInteger maxWidth = [self.dataCoordinator maxWidth] * 1.5;
        if(self.whichTableCoordinator.indexOfSelectedItem == 1){
            [self.threeDHandler startBufferForImages:self.dataCoordinator.inOrderImageWrappers.copy channels:[self.dataCoordinator maxChannels] width:maxWidth height:maxWidth];
        }else if(self.whichTableCoordinator.indexOfSelectedItem == 5){
            [self.threeDHandler startBufferForImages:self.dataCoordinator.computations.copy channels:[self.dataCoordinator maxChannelsComputations] width:maxWidth height:maxWidth];
        }else if(self.whichTableCoordinator.indexOfSelectedItem == 7){
            //TODO
            //Render 3D Mask
        }
        self.threeDHandler.interestProportions = self.scrollViewBlends.imageView.selectedArea;
        self.openGlViewPort.delegate = self;
        [self addBuffersForStackImages:sender];
    }
}
-(void)redoZ:(NSButton *)sender{
    if([self canRender])
        [self.threeDHandler prepDeltasAndProportionsWithStacks];
}
-(void)addBuffersForStackImages:(NSButton *)sender{
    if([self canRender]){
        self.threeDProcessesIndicator.doubleValue = .0f;
        dispatch_queue_t queue = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
        dispatch_async(queue, ^{
            if(![self.threeDHandler isReady])
                return;
            if(self.channels.selectedRowIndexes.count == 0)
                return;
            
            NSIndexSet *channs = self.channels.selectedRowIndexes.copy;
            NSIndexSet * objects = self.filesTree.selectedRowIndexes.copy;
            __block NSInteger ongoing = 0;
            __block NSInteger completed = 0;
            
            bool * seen = (bool *)calloc(objects.count, sizeof(bool));
            
            [objects enumerateIndexesUsingBlock:^(NSUInteger fileIdx, BOOL *stop){
                while (ongoing > 3);
                ongoing++;
                
                dispatch_queue_t internalQueue = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
                dispatch_async(internalQueue, ^{
                    
                    NSInteger external = [self.threeDHandler externalSliceIndexForInternal:fileIdx];
                    if(seen[external] == false){
                        seen[external] =  true;
                        IMCNodeWrapper *anobj;
                        anobj= [self.filesTree itemAtRow:fileIdx];
                        
                        IMCImageStack *stack;
                        IMCComputationOnMask *comp;
                        IMCPixelClassification *mask;
                        
                        if([anobj isMemberOfClass:[IMCImageStack class]])
                            stack = (IMCImageStack *)anobj;
                        if([anobj isMemberOfClass:[IMCFileWrapper class]])
                            stack = [(IMCFileWrapper *)anobj allStacks].firstObject;
                        if([anobj isMemberOfClass:[IMCPanoramaWrapper class]])
                            stack = (IMCImageStack *)[(IMCPanoramaWrapper *)anobj children].firstObject;
                        if([anobj isMemberOfClass:[IMCComputationOnMask class]]){
                            comp = (IMCComputationOnMask *)anobj;
                            stack = comp.mask.imageStack;
                        }
                        if([anobj isMemberOfClass:[IMCPixelClassification class]])
                            mask = (IMCPixelClassification *)anobj;
                        
                        if(stack && !comp){
                            [stack openIfNecessaryAndPerformBlock:^{
                                [channs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                                    [self.threeDHandler addImageStackatIndex:fileIdx channel:idx];
                                }];
                            }];
                            
                        }else if(mask){
                            [mask openIfNecessaryAndPerformBlock:^{
                                [self.threeDHandler addMask:mask atIndexOfStack:fileIdx maskOption:(MaskOption)self.maskVisualizeSelector.selectedSegment maskType:(MaskType)self.maskPartsSelector.selectedSegment];
                            }];
                        }else if(comp){
                            [comp openIfNecessaryAndPerformBlock:^{
                                [channs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                                    [self.threeDHandler addComputationAtIndex:fileIdx channel:idx maskOption:(MaskOption)self.maskVisualizeSelector.selectedSegment maskType:(MaskType)self.maskPartsSelector.selectedSegment];
                                }];
                            }];
                        }
                    }
                    ongoing--;
                    completed++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.threeDProcessesIndicator.doubleValue += 100.f/objects.count;
                    });
                });
            }];
            while (completed < objects.count);
            [self.threeDHandler meanBlurModelWithKernel:3 forChannels:channs mode:self.cleanUpMode.indexOfSelectedItem];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self calculateMemory];
                self.threeDProcessesIndicator.doubleValue = 0.0f;
                [self.openGlViewPort setNeedsDisplay:YES];
                sender.enabled = YES;
                free(seen);
            });
        });
    }
}

#pragma mark OpenGL and Metal delegate

-(UInt8 ***)threeDData{
    return self.threeDHandler.allBuffer;
}
-(bool *)showMask{
    return self.threeDHandler.showMask;
}
-(NSArray *)colors{
    if(self.colorSpaceSelector.selectedSegment == 3 && self.metalView)
        return nil;
    return [self.customChannelsDelegate collectColors];
}
-(NSColor *)backgroundColor{
    return self.background3D.color;
}
-(CGRect)rectToRender{
    return self.scrollViewBlends.imageView.selectedArea;
}
-(NSUInteger)witdhModel{
    return self.threeDHandler.width;
}
-(NSUInteger)heightModel{
    return self.threeDHandler.height;
}
-(NSUInteger)numberOfChannels{
    return self.threeDHandler.channels;
}
-(NSUInteger)numberOfStacks{
    if(self.inScope3DMask)
        return self.dataCoordinator.inOrderImageWrappers.count;
    return self.threeDHandler.images;
}
-(NSIndexSet *)stacksIndexSet{
    if(self.inScope3DMask)
        return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.dataCoordinator.inOrderImageWrappers.count)];
    return self.filesTree.selectedRowIndexes;
}
-(NSArray *)zOffSets{
    return nil;
}
-(float)combinedAlpha{
    return self.thresholdToRender.floatValue;
}
-(AlphaMode)alphaMode{
    switch (self.alphaModeSelector.selectedSegment) {
        case 1:
            return ALPHA_MODE_FIXED;
        case 2:
            return ALPHA_MODE_ADAPTIVE;
        default:
            break;
    }
    return ALPHA_MODE_OPAQUE;
}
-(float)sizeLabels{
    return self.legendsFontSize.floatValue;
}
-(float)cellModifierFactor{
    return self.cellModifier.floatValue;
}
-(NSInteger)boostModeCode{
    return self.boostMode.indexOfSelectedItem;
}
-(ColoringType)coloringType{
    return self.lightModeSelector.selectedSegment == 0 ? COLORING_TYPE_DIFFUSE_LIGHT_0 : COLORING_TYPE_DIFFUSE_EMISSIVE;
    //return COLORING_TYPE_DIFFUSE_EMISSIVE;
}
-(float *)zValues{
    return [self.threeDHandler zValues];
}
-(float *)thicknesses{
    return [self.threeDHandler thicknesses];
}
-(float)defaultThicknessValue{
    return self.stepperDefaultZ.floatValue;
}
-(float)totalThickness{
    return [self.threeDHandler totalThickness];
}
-(NSPoint)centerInterestArea{
    return [self.threeDHandler proportionalOffsetToCenter];
}
-(IBAction)refresh3D:(id)sender{
    [self.openGlViewPort refresh];
    self.metalViewDelegate.forceColorBufferRecalculation = YES;
}
-(NSArray *)inOrderIndexesArranged{
    return self.threeDHandler.indexesArranged;
}
#pragma mark record video

-(void)recordVideo:(NSButton *)sender{
    sender.tag = !(BOOL)sender.tag;
    sender.title = sender.tag == 0 ? @"Record Video" : @"Stop!";
    recordingVideo = (BOOL)sender.tag;
    
    if(recordingVideo){
        NSSize size = NSMakeSize(self.metalView.lastRenderedTexture.width, self.metalView.lastRenderedTexture.height);
        NSString *fullPath = [NSString stringWithFormat:@"%@%@.mp4", self.fileURL.path, [NSDate date].description];
        
        if(self.videoType.indexOfSelectedItem == 0)
            [IMC3DVideoPrograms recordYVideoWithPath:fullPath size:size framDuration:50 metalView:self.metalView active:&recordingVideo];
        if(self.videoType.indexOfSelectedItem == 1)
            [IMC3DVideoPrograms recordStackVideoWithPath:fullPath size:size framDuration:16 metalView:self.metalView slices:self.threeDHandler.images active:&recordingVideo];
        if(self.videoType.indexOfSelectedItem == 2)
            [IMC3DVideoPrograms recordSliceVideoWithPath:fullPath size:size framDuration:16 metalView:self.metalView slices:self.threeDHandler.images active:&recordingVideo];
        if(self.videoType.indexOfSelectedItem == 3)
            [IMC3DVideoPrograms recordRockVideoWithPath:fullPath size:size framDuration:16 metalView:self.metalView active:&recordingVideo];
    }
}

#pragma mark Segment Cells and pixel classification

-(void)segmentCells:(id)sender{
    if(self.inScopeImage.isLoaded){
        IMCCellSegmentation *seg = [[IMCCellSegmentation alloc]initWithStack:self.inScopeImage andTraining:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
}
-(void)segmentCellsBatch:(id)sender{
    IMCSegmentationBatch *seg;
    for (id obj in self.batchWindows)
        if([obj isMemberOfClass:[IMCSegmentationBatch class]])
            seg = (IMCSegmentationBatch *)obj;
    
    if(!seg)seg = [[IMCSegmentationBatch alloc]init];
    
    seg.delegate = self;
    if(![self.batchWindows containsObject:seg])
        [self.batchWindows addObject:seg];
    
    [[seg window] makeKeyAndOrderFront:seg];
    [seg.mapsTableView reloadData];
}
-(void)pixelClassify:(id)sender{
    if(self.inScopeImage.isLoaded){
        IMCPixelClassificationTool *seg = [[IMCPixelClassificationTool alloc]initWithStack:self.inScopeImage andTraining:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
}

-(void)pixelClassificatonBatch:(id)sender{
    IMCPixelClassificationBatch *seg;
    for (id obj in self.batchWindows)
        if([obj isMemberOfClass:[IMCPixelClassificationBatch class]])
            seg = (IMCPixelClassificationBatch *)obj;
    
    if(!seg)
        seg = [[IMCPixelClassificationBatch alloc]init];

    seg.delegate = self;
    if(![self.batchWindows containsObject:seg])
        [self.batchWindows addObject:seg];
    [[seg window] makeKeyAndOrderFront:seg];
    [seg.trainingsTableView reloadData];
    [seg.stacksTableView reloadData];
    
}
-(void)thresholdMask:(id)sender{
    if(self.inScopeImage.isLoaded){
        IMCThresholdMask *seg = [[IMCThresholdMask alloc]initWithStack:self.inScopeImage andMask:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
}
-(void)manualMask:(id)sender{
    if(self.inScopeImage.isLoaded){
        IMCPaintMask *seg = [[IMCPaintMask alloc]initWithStack:self.inScopeImage andMask:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
}
-(void)thresholdMaskBatch:(id)sender{
    IMCThresholdBatch *seg;
    for (id obj in self.batchWindows)
        if([obj isMemberOfClass:[IMCThresholdBatch class]])
            seg = (IMCThresholdBatch *)obj;
    
    if(!seg)
        seg = [[IMCThresholdBatch alloc]init];
    
    seg.delegate = self;
    if(![self.batchWindows containsObject:seg])
        [self.batchWindows addObject:seg];
    [[seg window] makeKeyAndOrderFront:seg];
}
-(void)combineMasks:(id)sender{
    IMCCombineMasks *seg = [[IMCCombineMasks alloc]init];
    seg.delegate = self;
    [[seg window] makeKeyAndOrderFront:seg];
}
-(void)cellClassification:(id)sender{
    if(self.inScopeComputation.isLoaded){
        IMCCellTrainerTool *seg = [[IMCCellTrainerTool alloc]initWithComputation:self.inScopeComputation andTraining:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
//    if(self.inScope3DMask.isLoaded){
//        IMCCell3DTrainerTool *seg = [[IMCCell3DTrainerTool alloc]initWithComputation:self.inScope3DMask andTraining:nil];
//        [[seg window] makeKeyAndOrderFront:seg];
//    }
    if(self.inScope3DMask.isLoaded){
        IMCSceneKitClassifier *seg = [[IMCSceneKitClassifier alloc]initWithComputation:self.inScope3DMask andTraining:nil];
        [[seg window] makeKeyAndOrderFront:seg];
    }
}
-(void)cellClassificationBatch:(id)sender{
    IMCCellClassificationBatch *seg;
    for (id obj in self.batchWindows)
        if([obj isMemberOfClass:[IMCCellClassificationBatch class]])
            seg = (IMCCellClassificationBatch *)obj;
    
    if(!seg)
        seg = [[IMCCellClassificationBatch alloc]init];
    
    seg.delegate = self;
    if(![self.batchWindows containsObject:seg])
        [self.batchWindows addObject:seg];
    [[seg window] makeKeyAndOrderFront:seg];
    [seg.trainingsTableView reloadData];
    [seg.computationsTableView reloadData];
}

//Delegate batch PixClass
-(NSArray *)allStacks{
    return self.dataCoordinator.inOrderImageWrappers;
}
-(NSArray *)allTrainings{
    return self.dataCoordinator.pixelTrainings;
}
-(NSArray *)allCellTrainings{
    return self.dataCoordinator.maskTrainings;
}
-(NSArray *)allComputations{
    return self.dataCoordinator.computations;
}
-(NSArray *)allThresholdPixClassifications{
    NSArray *masks = [self.dataCoordinator masks];
    NSMutableArray * collected = @[].mutableCopy;
    for(IMCPixelClassification *mask in masks)
        if(mask.isThreshold)
            [collected addObject:mask];
    return collected;
}
-(NSArray *)allMapsForSegmentation{
    NSMutableArray *array = @[].mutableCopy;
    for (IMCPixelMap *map in self.dataCoordinator.pixelMaps)
        //if([map.jsonDictionary[JSON_DICT_PIXEL_MAP_FOR_SEGMENTATION]boolValue])
            [array addObject:map];
    return array;
}

#pragma mark GGPlot

-(void)refreshGGPlot:(id)sender{
    [self.plotHandler.plotter prepareDataMultiImage:[self computations] channels:[self channelIndexesPlotting]];
    if(self.rMiniConsole.window.isVisible)
        self.plotResult.imageView.image = [self.plotHandler.plotter runWithScript:self.rMiniConsole.rScript.string];
    else
        self.plotResult.imageView.image = [self.plotHandler getImageDerivedFromDelegate];
}
-(void)showRMiniConsole:(id)sender{
    if(!self.rMiniConsole)self.rMiniConsole = [[IMCMiniRConsole alloc]init];
    [[self.rMiniConsole window] makeKeyAndOrderFront:self.rMiniConsole];
    self.rMiniConsole.rScript.string = [self.plotHandler getScriptDerivedFromDelegate];
}
-(NSInteger)typeOfPlot{
    return self.plotType.indexOfSelectedItem;
}

-(NSArray *)channelIndexesPlotting{
    return self.channelsInScopeForPlotting;
}
-(NSArray *)channelNames{
    NSMutableArray *names = @[].mutableCopy;
    for (NSString *str in [self channelsForCell]) {
        [names addObject:[str sanitizeFileNameString]];
    }
    return names;
}
-(NSInteger)xMode{
    return self.xLog.selectedSegment;
}
-(NSInteger)yMode{
    return self.yLog.selectedSegment;
}
-(NSInteger)cMode{
    return self.cLog.selectedSegment;
}
-(NSInteger)xChann{
    return self.xChannel.indexOfSelectedItem;
}
-(NSInteger)yChann{
    return self.yChannel.indexOfSelectedItem;
}
-(NSInteger)sChann{
    return self.sChannel.indexOfSelectedItem;
}
-(NSInteger)cChann{
    return self.cChannel.indexOfSelectedItem;
}
-(NSInteger)f1Chann{
    return self.f1Channel.indexOfSelectedItem;
}
-(NSInteger)f2Chann{
    return self.f2Channel.indexOfSelectedItem;
}
-(CGFloat)alphaGeomp{
    return self.alphaGeompSlider.floatValue;
}
-(CGFloat)sizeGeomp{
    return self.sizeGeompSlider.floatValue;
}
-(NSColor *)colorPointsChoice{
    return self.colorPoints.color;
}
-(NSInteger)colorScaleChoice{
    return self.colorScale.indexOfSelectedItem;
}

#pragma mark 3D masks
-(void)showMasker:(id)sender{
    IMC3dMasking *seg = [[IMC3dMasking alloc]init];
    seg.delegate = self;
    [[seg window] makeKeyAndOrderFront:seg];
}
-(void)threeDMasking:(Mask3D_Type)type{
    if(self.inOrderIndexes.count > 0){
        IMC3DMask *mask3d = [[IMC3DMask alloc]initWithLoader:self.dataCoordinator andHandler:self.threeDHandler];
        NSMutableArray *array = @[].mutableCopy;
        NSArray *add;
        if(self.whichTableCoordinator.indexOfSelectedItem == 1)
            add = self.dataCoordinator.inOrderImageWrappers.copy;
        if(self.whichTableCoordinator.indexOfSelectedItem == 5)
            add = self.dataCoordinator.inOrderComputations.copy;
        
        if(!add && ![self canRender])return;
        
        for (IMCNodeWrapper *node in add)
            [array addObject:node.itemHash];
        
        [mask3d setTheComponents:array];
        mask3d.channel = [self.inOrderIndexes.firstObject integerValue];
        mask3d.channelsWS = self.inOrderIndexes.copy;
        
//        if(self.inOrderIndexes.count == 2)
//            mask3d.substractChannel = [self.inOrderIndexes.lastObject integerValue];//self.channels.selectedRow;
        
        mask3d.origin = self.whichTableCoordinator.indexOfSelectedItem == 1? MASK3D_VOXELS : MASK3D_2D_MASKS;
        
        
        NSString *input;
        do{
            input = [IMCUtils input:@"Minimum number of voxels per kernel (e.g.: 12-10000)" defaultValue:@"20"];
            if(!input)
                return;
        }while (input.integerValue <= 0);
        mask3d.minKernel = input.integerValue;
        
        if(type == MASK3D_WATERSHED){
            do{
                input = [IMCUtils input:@"Step for watershed gradient (e.g.: 0.005-0.1)" defaultValue:@"0.02"];
                if(!input)
                    return;
            }while (input.floatValue <= 0);
            mask3d.stepWatershed = input.floatValue;
        }
        

        NSArray *channs = [@[@"None"] arrayByAddingObjectsFromArray:self.inScopeImage.channels.copy];
        mask3d.substractChannel = [IMCUtils inputOptions:channs prompt:@"Do you want to use a channel to frame the nuclear signal?"];
        if(mask3d.substractChannel == NSNotFound)
            return;
        if(mask3d.substractChannel == 0)
            mask3d.substractChannel = NSNotFound;
        else
            mask3d.substractChannel--;
        
        do{
            input = [IMCUtils input:@"Do you want to add expansion layer? (e.g.: 0-100)" defaultValue:@"2"];
            if(!input)
                return;
        }while (input.integerValue < 0);
        mask3d.expansion = input.integerValue;
        mask3d.threshold = self.thresholdToRender.floatValue;
        mask3d.sheepShaver = (BOOL)mask3d.minKernel;
        mask3d.type = type;
        
        [self.dataCoordinator giveNameToNode:mask3d inGroup:self.dataCoordinator.threeDNodes];
        [self.dataCoordinator add3DNode:mask3d];
        
        [mask3d extractMaskFromRender];
    }
}

-(void)create3DMaskFromCurrent:(id)sender{
    [self threeDMasking:MASK3D_WATERSHED];
}
-(void)create3DMaskByThresholding:(id)sender{
    [self threeDMasking:MASK3D_THRESHOLD];
}
-(void)create3DMaskByThresholdingKeepId:(id)sender{
    [self threeDMasking:MASK3D_THRESHOLD_SEGMENT];
}
-(NSArray *)masks{
    return [self.dataCoordinator masks];
}

#pragma mark watershed
-(IBAction)watershed2D:(id)sender{
    if(!self.inScopeImage || self.inOrderIndexes.count == 0)
        return;
    
    [IMCWaterShedSegmenter wizard2DWatershedIndexes:self.inOrderIndexes.copy scopeImage:self.inScopeImage scopeImages:self.inScopeImages.copy];
}

#pragma mark cluster

-(void)clusterFlock:(id)sender{
    if(self.inScope3DMask)
        //[self.inScope3DMask flockWithChannelindexes:self.channels.selectedRowIndexes.copy];
        [IMCComputationOnMask flockForComps:self.inScope3DMasks indexes:self.channels.selectedRowIndexes.copy];
    else
        [IMCComputationOnMask flockForComps:self.inScopeComputations indexes:self.channels.selectedRowIndexes.copy];
}
-(void)clusterKMeans:(id)sender{
    if(self.inScope3DMask)
        //[self.inScope3DMask flockWithChannelindexes:self.channels.selectedRowIndexes.copy];
        [IMCComputationOnMask kMeansForComps:self.inScope3DMasks indexes:self.channels.selectedRowIndexes.copy];
    else
        [IMCComputationOnMask kMeansForComps:self.inScopeComputations indexes:self.channels.selectedRowIndexes.copy];
}

#pragma mark analytics
//Metadata table
-(IBAction)addMetric:(id)sender{
    [self.metricsController addMetric];
}
-(IBAction)removeMetric:(id)sender{
    [self.metricsController removeMetric];
}

#pragma mark compensation
-(IBAction)flipCompensation:(NSButton *)sender{
    for (IMCImageStack *stack in self.dataCoordinator.inOrderImageWrappers)
        stack.usingCompensated = (BOOL)sender.state;
    [self refresh];
}

-(IBAction)compensationMatrix:(id)sender{
    if(!self.compensationSession){
        self.compensationHandler = [[IMCCompensation alloc]initWithDataCoordinator:self.dataCoordinator];
        self.compensationHandler.window.delegate = self;
        self.compensationSession = [NSApp beginModalSessionForWindow:self.compensationHandler.window];
    }
}
-(BOOL)windowShouldClose:(id)sender{
    [NSApp endModalSession:self.compensationSession];
    self.compensationHandler = nil;
    self.compensationSession = nil;
    return YES;
}

#pragma mark cell basic algorithms

-(void)cellBasicAlgorithms:(id)sender{//TODO, have several possibilities, and combine Comps
    
    IMCComputationOnMask *whichComp = self.inScopeComputation;
    if(!whichComp)
        whichComp = self.inScope3DMask;
    if(whichComp){
        [whichComp openIfNecessaryAndPerformBlock:^{
            _currentCellAnalysis = NULL;
            if(!self.cellAnalyses)
                self.cellAnalyses = @[].mutableCopy;
            for(IMCCellBasicAlgorithms *analys in self.cellAnalyses)
                if([analys containsComputations:@[whichComp]])
                    _currentCellAnalysis = analys;
            if(!_currentCellAnalysis){
                _currentCellAnalysis = [[IMCCellBasicAlgorithms alloc]initWithComputation:whichComp];
                _currentCellAnalysis.mainURL = self.fileURL.path;
                [self.cellAnalyses addObject:_currentCellAnalysis];
            }
            [[_currentCellAnalysis window] makeKeyAndOrderFront:_currentCellAnalysis];
        }];
    }
}

#pragma mark
-(void)cleanUpNamesWithAirlab:(id)sender{
    [IMCAirLabClient getInfoClones:self.inScopeImages subdomain:@"bodenmillerlab"];
}

#pragma mark
-(void)openPoisitionsTool:(id)sender{
    if(!self.positionsTool){
        self.positionsTool = [[IMCPositions alloc]initWithLoader:self.dataCoordinator andView:self.metalView andSV:self.scrollViewBlends];
        self.positionsTool.delegate = self;
    }
    [[self.positionsTool window] makeKeyAndOrderFront:self.positionsTool];
}

-(void)close{
    [super close];

}

#pragma mark close things properly
-(void)dealloc{
    for (IMCFileWrapper *wrapp in self.dataCoordinator.fileWrappers) {
        if (wrapp.isLoaded)
            [wrapp unLoadLayerDataWithBlock:nil];
    }
}

#pragma mark help
-(void)helpHC:(NSButton *)sender{
    [Help helpWithIdentifier:sender.identifier];
}

#pragma mark save
-(void)saveActionFromCoordinator{
    [self saveDocument:nil];
}

@end
