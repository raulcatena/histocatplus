//
//  IMCTSneWindowController.m
//  IMCReader
//
//  Created by Raul Catena on 9/12/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCCellBasicAlgorithms.h"
#import "IMCTsneOperation.h"
#import "IMCBhSNEOperation.h"
#import "IMCPCAOperation.h"
#import "IMCKMeansOperation.h"
#import "IMCFlockOperation.h"
#import "kmeans.h"
#import "IMCImageGenerator.h"
#import "NSView+Utilities.h"
#import "IMCComputationOnMask.h"
#import "IMC3DMask.h"
#import "flock.h"
#import "IMCVideoCreator.h"
#import "NSView+Utilities.h"

@interface IMCCellBasicAlgorithms (){
    int iterationsCursor;
    int clusteringCursor;
    float *newReducedData;
    int *newClusteredData;
    int *colorData;
    int nDim;
    int n;
    
    BOOL recording;
}
@property (nonatomic, strong) IMCComputationOnMask *computation;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSTimer *timer2;
@property (nonatomic, strong) NSOperationQueue *dimensionalityRedOperations;
@property (nonatomic, strong) NSMutableArray *dimensionalityRedOperationsArray;
@property (nonatomic, strong) NSOperationQueue *clusteringOperations;
@property (nonatomic, strong) NSMutableArray *clusteringOperationsArray;
@property (nonatomic, strong) NSArray *dashboards;

@end

@implementation IMCCellBasicAlgorithms


-(instancetype)initWithComputation:(IMCComputationOnMask *)computation{
    self = [self init];
    if(self)
        self.computation = computation;
    return self;
}
-(instancetype)initWith3DMask:(IMC3DMask *)computation{
    self = [self init];
    if(self)
        self.computation = computation;
    return self;
}

-(id)init{
    return [super initWithWindowNibName:NSStringFromClass([IMCCellBasicAlgorithms class]) owner:self];
}

-(BOOL)containsComputations:(NSArray<IMCComputationOnMask *> *)computations{
    for(IMCComputationOnMask *comp in computations)
        if(comp == self.computation)
            return YES;
    return NO;
}

-(void)assembleDashboards{
    if(!self.tsneDashboard)
        self.tsneDashboard = (IMCTsneDashboard *)[NSView loadWithNibNamed:NSStringFromClass([IMCTsneDashboard class]) owner:self class:[IMCTsneDashboard class]];
    if(!self.kmenasDashboard)
        self.kmenasDashboard = (IMCKMeansDashboard *)[NSView loadWithNibNamed:NSStringFromClass([IMCKMeansDashboard class]) owner:self class:[IMCKMeansDashboard class]];
    if(!self.dashboards)
        self.dashboards = @[self.tsneDashboard, self.kmenasDashboard];
    for (NSView *aV in self.dashboards) {
        [self.dashboardArea addSubview:aV];
        aV.hidden = YES;
    }
    self.tsneDashboard.hidden = NO;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.plot.delegatePlot = self;
    [self changedChoice:self.choiceDRAlgorithm];
    [self assembleDashboards];
    [self.tableDR setDoubleAction:@selector(addDR:)];
    [self.tableClust setDoubleAction:@selector(addClust:)];
    [self setChannelsInLists];
}
-(void)awakeFromNib{
    [super awakeFromNib];
    self.window.title = self.computation.itemName;
    [self.computation loadLayerDataWithBlock:nil];
}
-(void)setChannelsInLists{
    if(self.colorVariable && self.colorVariable2 && self.colorVariable3){
        NSArray *lists = @[_colorVariable, _colorVariable2, self.colorVariable3];
        for (NSPopUpButton *list in lists)[list removeAllItems];
        for (NSString *str in self.computation.channels) {
            for (NSPopUpButton *list in lists) {
                [list addItemWithTitle:@"blah"];
                [[list lastItem]setTitle:str.copy];
            }
        }
    }
}

-(float *)prepData{
    
    NSInteger selected = self.tableView.selectedRowIndexes.count;
    float *prep = (float *)calloc(self.computation.segmentedUnits * selected, sizeof(float));
    __block int cursor = 0;
    NSUInteger segments = [self.computation segmentedUnits];
    float ** comp = self.computation.computedData;
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        for (NSInteger i = 0; i < segments; i++)
            prep[i * selected + cursor] = asinh(comp[idx][i]);
        
        cursor++;
    }];
    return prep;
}

-(double *)prepDataDouble{
    
    NSInteger selected = self.tableView.selectedRowIndexes.count;
    double *prep = (double *)calloc(self.computation.segmentedUnits * selected, sizeof(double));
    NSUInteger segments = [self.computation segmentedUnits];
    __block int cursor = 0;
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        for (NSInteger i = 0; i < segments; i++) {
            prep[i * selected + cursor] = asinh(self.computation.computedData[idx][i]);
            //prep[i * selected + cursor] = (float)preData[i * self.channels.count + idx];
            //printf(" %i", preData[i * self.channels.count + idx]);
        }
        cursor++;
    }];
    return prep;
}

-(void)runTsne{
    int anIterationsCursor = 0;
    float *reducedDataOutput = (float*) calloc(self.computation.segmentedUnits * 2, sizeof(float));//not iVar anymore
    unsigned int chansToAnalyze = (unsigned int)[self.tableView.selectedRowIndexes count];
    
    IMCTsneOperation *op = [[IMCTsneOperation alloc]init];
    op.outputData = reducedDataOutput;
    op.inputData = [self prepData];
    op.numberOfValues = self.computation.segmentedUnits;
    op.numberOfVariables = chansToAnalyze;
    op.numberOfOutputVariables = 2;
    op.iterationCursor = anIterationsCursor;
    op.perplexity = self.tsneDashboard.perplexity.floatValue;
    op.numberOfCycles = 150;
    op.cyclesLying = 100;
    op.indexSet = [self.tableView.selectedRowIndexes copy];
    [self.dimensionalityRedOperationsArray addObject:op];
    [self.dimensionalityRedOperations addOperation:op];
}

-(void)runBhsne{
    int anIterationsCursor = 0;
    double *reducedDataOutput = (double*) calloc(self.computation.segmentedUnits * 2, sizeof(double));//not iVar anymore
    unsigned int chansToAnalyze = (unsigned int)[self.tableView.selectedRowIndexes count];
    
    IMCBhSNEOperation *op = [[IMCBhSNEOperation alloc]init];
    op.outputDataDouble = reducedDataOutput;
    op.inputDataDouble = [self prepDataDouble];
    op.numberOfValues = self.computation.segmentedUnits;
    op.numberOfVariables = chansToAnalyze;
    op.numberOfOutputVariables = 2;
    op.iterationCursor = anIterationsCursor;
    op.perplexity = self.tsneDashboard.perplexity.floatValue;
    op.thetha = 0.1f;
    op.numberOfCycles = 1000;
    op.cyclesLying = 100;
    op.indexSet = [self.tableView.selectedRowIndexes copy];
    [self.dimensionalityRedOperationsArray addObject:op];
    [self.dimensionalityRedOperations addOperation:op];
}

-(void)runPCA{
    float *reducedDataOutput = (float*) calloc(self.computation.segmentedUnits * 2, sizeof(float));//not iVar anymore
    unsigned int chansToAnalyze = (unsigned int)[self.tableView.selectedRowIndexes count];
    IMCPCAOperation *op = [[IMCPCAOperation alloc]init];
    op.outputData = reducedDataOutput;
    op.inputData = [self prepData];
    op.numberOfValues = self.computation.segmentedUnits;
    op.numberOfVariables = chansToAnalyze;
    op.numberOfOutputVariables = 2;
    op.indexSet = [self.tableView.selectedRowIndexes copy];
    [self.dimensionalityRedOperationsArray addObject:op];
    [self.dimensionalityRedOperations addOperation:op];
}

-(void)runKmeans{
    int aClusteringCursor = 0;
    
    int *reducedDataOutput = (int*) calloc(self.computation.segmentedUnits * 2, sizeof(int));//not iVar anymore
    //unsigned int chansToAnalyze = (unsigned int)[self.tableView.selectedRowIndexes count];
    IMCKMeansOperation *op = [[IMCKMeansOperation alloc]init];
    op.outputDataInt = reducedDataOutput;
    op.inputData = newReducedData != NULL && self.tableDR.selectedRowIndexes.count > 0?newReducedData:[self prepData];
    op.numberOfValues = self.computation.segmentedUnits;
    op.numberOfVariables = 2;
    op.iterationCursor = aClusteringCursor;
    op.numberOfClusters = self.kmenasDashboard.clusters.intValue;
    op.numberOfRestarts = self.kmenasDashboard.restarts.intValue;
    op.indexSet = [self.tableView.selectedRowIndexes copy];
    [self.clusteringOperationsArray addObject:op];
    [self.clusteringOperations addOperation:op];
}

-(void)runFlock{
    
    int aClusteringCursor = 0;
    int *clusters = (int *) calloc(self.computation.segmentedUnits, sizeof(int));//not iVar anymore
    
    NSInteger segments = self.computation.segmentedUnits;
    unsigned int chansToAnalyze = (unsigned int)[self.tableView.selectedRowIndexes count];
    double ** input = (double **)malloc(segments * sizeof(double *));
    for (NSInteger i = 0; i < segments; i++)
        input[i] = (double *)malloc(chansToAnalyze * sizeof(double));
    __block int counter = 0;
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        for (NSInteger i = 0; i < segments; i++)
            input[i][counter] = (double)asinh(self.computation.computedData[idx][i]);
        counter++;
    }];
        
    IMCFlockOperation *op = [[IMCFlockOperation alloc]init];
    op.outputDataInt = clusters;
    op.flockInput = input;
    op.numberOfValues = segments;
    op.numberOfCycles = 2;
    op.numberOfVariables = chansToAnalyze;
    op.iterationCursor = aClusteringCursor;
    op.indexSet = [self.tableView.selectedRowIndexes copy];
    [self.clusteringOperationsArray addObject:op];
    [self.clusteringOperations addOperation:op];
}

-(void)runReducer:(NSButton *)sender{
    
    if(!self.dimensionalityRedOperations)self.dimensionalityRedOperations = [[NSOperationQueue alloc]init];
    if(!self.dimensionalityRedOperationsArray)self.dimensionalityRedOperationsArray = [NSMutableArray array];
    
    switch (self.choiceDRAlgorithm.indexOfSelectedItem) {
        case 0:
            [self runTsne];
            break;
        case 1:
            [self runBhsne];
            break;
        case 2:
            [self runPCA];
            break;
            
        default:
            break;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkProgressReducer) userInfo:nil repeats:YES];
    [self.timer fire];
}

-(void)runClusterer:(id)sender{
    
    if(!self.clusteringOperations)self.clusteringOperations = [[NSOperationQueue alloc]init];
    if(!self.clusteringOperationsArray)self.clusteringOperationsArray = [NSMutableArray array];
    
    switch (self.choiceClustAlgorithm.indexOfSelectedItem) {
        case 0:
            [self runKmeans];
            break;
            
        case 1:
            [self runFlock];
            break;
            
        default:
            break;
    }
    
    [self.timer2 invalidate];
    self.timer2 = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkProgressClusterer) userInfo:nil repeats:YES];
    [self.timer2 fire];
}

-(void)checkProgressReducer{
    [self.tableDR reloadData];
    
    for (IMCTsneOperation *op in self.dimensionalityRedOperations.operations) {
        if(op.iterationCursor == op.numberOfCycles && self.dimensionalityRedOperations.operations.count == 0)[self.timer invalidate];
    }
    
    [self updateGraph:nil];
}

-(void)checkProgressClusterer{
    [self.tableClust reloadData];
    
    for (IMCTsneOperation *op in self.clusteringOperations.operations) {
        if(op.iterationCursor == op.numberOfCycles && self.clusteringOperations.operations.count == 0)[self.timer2 invalidate];
    }
    [self updateGraph:nil];
}

-(void)saveOp:(IMCTsneOperation *)op block:(void(^)())block{
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"OK"];
    
    if(op.opFinished == YES){
        if(op.opAdded == YES){
            alert.messageText = @"The results of this operation have already been added";
        }else{
            alert.messageText = @"Do you want to add the data to as variables to the segmented set?";
            [alert addButtonWithTitle:@"Cancel"];
        }
    }else{
        alert.messageText = @"This operation has not yet finished";
    }
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn && op.finished == YES && op.opAdded == NO) {
        if(block)block();
    }
    [self.tableView reloadData];
}

-(void)addDR:(id)sender{
    IMCTsneOperation *op = [self.dimensionalityRedOperationsArray objectAtIndex:self.tableDR.selectedRow];
    
    NSInteger segments = self.computation.segmentedUnits;
    NSInteger outVars = op.numberOfOutputVariables;
    
    if([op isMemberOfClass:[IMCBhSNEOperation class]]){//Has doubles
        [self saveOp:op block:^{
            double *outputDouble = op.outputDataDouble;
            
            for (int i = 0; i < outVars; i++){
                float * output = calloc(segments, sizeof(float));
                for (NSInteger j = 0; j < segments; j++)
                    output[j] = (float)(outputDouble[j * outVars + i]);
                [self.computation addBuffer:output withName:[NSString stringWithFormat:@"%@_%i", op.nameGiven, i+1] atIndex:NSNotFound];
            }
            op.opAdded = YES;
        }];
    }else{
        [self saveOp:op block:^{
            float *outputFloat = op.outputData;

            NSInteger segments = self.computation.segmentedUnits;
            for (int i = 0; i < outVars; i++){
                float * output = calloc(self.computation.segmentedUnits, sizeof(float));
                for (NSInteger j = 0; j < segments; j++)
                    output[j] = (float)(outputFloat[j * outVars + i]);
                [self.computation addBuffer:outputFloat withName:[NSString stringWithFormat:@"%@_%i", op.nameGiven, i+1] atIndex:NSNotFound];
            }
            
            op.opAdded = YES;
        }];
    }
}

-(void)addClust:(id)sender{
    IMCTsneOperation *op = [self.clusteringOperationsArray objectAtIndex:self.tableClust.selectedRow];
    [self saveOp:op block:^{
        int *outputInt = op.outputDataInt;
        float * output = calloc(self.computation.segmentedUnits * op.numberOfOutputVariables, sizeof(float));
        for (NSInteger i = 0; i < self.computation.segmentedUnits * op.numberOfOutputVariables; i++) {
            output[i] = (float)outputInt[i] + 1.0f;
        }
        for (int i = 0; i < op.numberOfOutputVariables; i++)
            [self.computation addBuffer:output withName:[NSString stringWithFormat:@"%@_%i", op.nameGiven, i+1] atIndex:NSNotFound];
        op.opAdded = YES;
    }];
}

-(void)updateGraph:(id)sender{
    if(newReducedData == NULL)return;
    if(self.plot)[self.plot setNeedsDisplay:YES];
}

-(void)changedColorSelector:(id)sender{
    if(self.colorVariableActive.state == NSOffState){
        if(colorData != NULL){
            free(colorData);
            colorData = NULL;
        }
    }else{
        colorData = (int *)calloc(self.computation.segmentedUnits * 3, sizeof(int));
        float ** preData = self.computation.computedData;
        NSInteger index = self.colorVariable.indexOfSelectedItem;
        NSInteger index2 = self.colorVariable2.indexOfSelectedItem;
        NSInteger index3 = self.colorVariable3.indexOfSelectedItem;
        
        float maxLocal = 0;
        float maxLocal2 = 0;
        float maxLocal3 = 0;
        for (NSInteger i = 0; i < self.computation.segmentedUnits; i++){
            if(preData[index][i] > maxLocal)maxLocal = preData[index][i];
            if(preData[index2][i] > maxLocal2)maxLocal2 = preData[index2][i];
            if(preData[index3][i] > maxLocal3)maxLocal3 = preData[index3][i];
        }
        //maxLocal /= 10;
        for (NSInteger i = 0; i < self.computation.segmentedUnits; i++){
            colorData[i * 3] = MIN((int)((float)preData[index][i]/maxLocal*255.0f)/self.burnColorPoints.floatValue, 255);
            if (self.coloringType.selectedSegment == 1) {
                if(self.showColor2.state == NSOnState)colorData[i * 3 + 1] = MIN((int)(preData[index2][i]/maxLocal2*255.0f)/self.burnColorPoints2.floatValue, 255);
                if(self.showColor3.state == NSOnState)colorData[i * 3 + 2] = MIN((int)(preData[index3][i]/maxLocal3*255.0f)/self.burnColorPoints3.floatValue, 255);
            }
            
            if(self.coloringType.selectedSegment == 2){
                HsvColor hsv;
                //hsv.h = (int)(255.0f/maxLocal * preData[i * channelsCount + index]);
                int val = (int)(170 - (255.0f/maxLocal * preData[index][i] * 2 /3));//New RCF20161026
                hsv.h = val;//New
                hsv.s = 255;
                hsv.v = 255;
                RgbColor rgb = HsvToRgb(hsv);
                colorData[i * 3] = rgb.r;
                colorData[i * 3 + 1] = rgb.g;
                colorData[i * 3 + 2] = rgb.b;
            }
        }
    }
    
    BOOL hideOthers = YES;
    if(self.coloringType.selectedSegment == 1)hideOthers = NO;
    NSArray *hideables = @[self.colorVariable2, self.colorVariable3, self.burnColorPoints2, self.burnColorPoints3, self.showColor2, self.showColor3];
    for (NSView *aV in hideables) {
        aV.hidden = hideOthers;
    }
    
    [self updateGraph:nil];
}

-(void)changedChoice:(NSPopUpButton *)sender{
    for(NSView *aV in self.dashboards)aV.hidden = YES;
    if(sender == self.choiceDRAlgorithm)if(sender.indexOfSelectedItem < 2)self.tsneDashboard.hidden = NO;
    if(sender == self.choiceClustAlgorithm)if(sender.indexOfSelectedItem == 0)self.kmenasDashboard.hidden = NO;
}

-(void)saveData:(NSButton *)sender{
    [self.computation saveData];
}

#pragma mark tableview

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if(tableView == self.tableDR)return self.dimensionalityRedOperationsArray.count;
    if(tableView == self.tableClust)return self.clusteringOperationsArray.count;
    return self.computation.channels.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    if(tableView == self.tableDR)return [[self.dimensionalityRedOperationsArray objectAtIndex:row]description];
    if(tableView == self.tableClust)return [[self.clusteringOperationsArray objectAtIndex:row]description];
    return [self.computation.channels objectAtIndex:row];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    NSString *strX = self.overrideXAxisLabel.stringValue;
    NSString *strY = self.overrideXAxisLabel.stringValue;
    
    if (notification.object == self.tableDR) {
        if(self.tableDR.selectedRow < 0)return;
        IMCTsneOperation *op = [self.dimensionalityRedOperationsArray objectAtIndex:self.tableDR.selectedRow];
        [self.tableView selectRowIndexes:op.indexSet byExtendingSelection:NO];
        newReducedData = op.outputData;
        
        self.plot.titlesX = strX.length > 0?@[strX]:@[[NSString stringWithFormat:@"%@_1", op.nameGiven]];
        self.plot.titlesXY = strY.length > 0?@[strY]:@[[NSString stringWithFormat:@"%@_2", op.nameGiven]];
    }
    
    
    if (notification.object == self.tableView) {
        
        float * data = (float*)calloc(self.computation.segmentedUnits * 2, sizeof(float));
        
        __block int cursor = 0;
        
        [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            
            if(cursor == 0)
                self.plot.titlesX = strX.length > 0 ? @[strX] : @[[self.computation.channels objectAtIndex:index]];
            else
                self.plot.titlesXY = strY.length > 0 ? @[strY] : @[[self.computation.channels objectAtIndex:index]];
            
            for (NSInteger i = 0; i < self.computation.segmentedUnits; i++){
                    data[i * 2 + cursor] = self.computation.computedData[index][i];
            }
            
            cursor++;
            
            if(cursor == 2)*stop = YES;
        }];
        if(newReducedData != NULL)
            free(newReducedData);
        newReducedData = data;
    }
    [self updateGraph:nil];
}

#pragma mark Biaxial view

-(float *)floatBiaxialData{
    
    if(self.tableDR.selectedRow >= 0){
        IMCTsneOperation *op = [self.dimensionalityRedOperationsArray objectAtIndex:self.tableDR.selectedRow];
        [self.tableView selectRowIndexes:op.indexSet byExtendingSelection:NO];
        return op.outputData;
    }
    
    return newReducedData;
}
-(int)sizeOfData{
    return (int)self.computation.segmentedUnits;
}
-(int *)colorDataForThirdDimension{
    
    return colorData;
}

-(BOOL)heatColorMode{
    return self.coloringType.selectedSegment == 0?YES:NO;
}

-(NSString *)topLabel{
    if(self.overrideTitleGraph.stringValue.length > 0)return self.overrideTitleGraph.stringValue;
    return [self.computation.channels objectAtIndex:self.colorVariable.indexOfSelectedItem];
}

#pragma mark formating plot


-(void)changedColorPoints:(NSColorWell *)sender{
    self.plot.pointsColor = sender.color;
    [self.plot setNeedsDisplay:YES];
}
-(void)changedSizePoints:(NSSlider *)sender{
    self.plot.sizePoints = sender.floatValue;
    [self.plot setNeedsDisplay:YES];
}
-(void)changedTransparencyPoints:(NSSlider *)sender{
    self.plot.transparencyPoints = sender.floatValue;
    [self.plot setNeedsDisplay:YES];
}
-(void)changedColorAxes:(NSColorWell *)sender{
    self.plot.axesColor = sender.color;
    [self.plot setNeedsDisplay:YES];
}
-(void)changedSizeAxes:(NSSlider *)sender{
    self.plot.axesPointSize = sender.floatValue;
    [self.plot setNeedsDisplay:YES];
}

-(void)changedWidthAxes:(NSSlider *)sender{
    self.plot.thicknessAxes = sender.floatValue;
    [self.plot setNeedsDisplay:YES];
}

-(void)changedColorBckg:(NSColorWell *)sender{
    self.plot.backGroundCol = sender.color;
    [self.plot setNeedsDisplay:YES];
}

#pragma mark copy image

- (IBAction)copy:sender {
    NSImage *image = [self.plot getImageBitMapFromRect:self.plot.frame];
    if (image != nil) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        NSArray *copiedObjects = [NSArray arrayWithObject:image];
        [pasteboard writeObjects:copiedObjects];
    }
}

#pragma mark

-(IBAction)startStopCreateVideo:(NSButton *)sender{
    sender.tag = !(BOOL)sender.tag;
    sender.title = sender.tag == 0 ? @"Record Video" : @"Stop!";
    recording = (BOOL)sender.tag;
    
    if(recording){
        
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@.mp4", self.mainURL.stringByDeletingLastPathComponent, [NSDate date].description];
        
        [self runReducer:nil];
        
        IMCVideoCreator *videoRecorder = [[IMCVideoCreator alloc]initWithSize:self.plot.bounds.size duration:16 path:fullPath];
        IMCMathOperation *op = self.dimensionalityRedOperations.operations.lastObject;
        
        [self.tableDR selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.dimensionalityRedOperations.operations indexOfObject:op]] byExtendingSelection:NO];
        
        dispatch_queue_t aQ = dispatch_queue_create("aQQQ", NULL);
        dispatch_async(aQ, ^{
            int cycle = op.iterationCursor;
            while (recording) {
                while (op.iterationCursor == cycle);
                dispatch_async(dispatch_get_main_queue(), ^{[self updateGraph:nil];});
                cycle = op.iterationCursor;
                UInt8 *buff = [self.plot bufferForView];//NULL
                [videoRecorder addBuffer:buff];
                free(buff);
            }
            [videoRecorder finishVideo];
        });
    }
}

@end
