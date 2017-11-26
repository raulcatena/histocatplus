//
//  IMCCombineMasks.m
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCombineMasks.h"
#import "IMCImageStack.h"
#import "IMCPixelClassification.h"
#import "IMCPixelMap.h"
#import "IMCComputationOnMask.h"
#import "IMCImageGenerator.h"
#import "NSImage+OpenCV.h"
#import "IMCMasks.h"

@interface PixelStruct: NSObject {
    @public
    int * mask;
    NSUInteger width;
    NSUInteger height;
}
@end
@implementation PixelStruct
@end

@interface IMCCombineMasks (){
    float * results;
}
@property (nonatomic, strong) NSMutableArray <IMCPixelClassification *> *arrSegmentationMasks;
@property (nonatomic, strong) NSMutableArray <IMCNodeWrapper *>*arrAllMasks;
@end

@implementation IMCCombineMasks

-(PixelStruct *)structFromObject:(IMCNodeWrapper *)node withCertainty:(float)certainty{
    PixelStruct *st = [[PixelStruct alloc]init];
    if([node isMemberOfClass:[IMCPixelClassification class]]){
        IMCPixelClassification *mask = (IMCPixelClassification *)node;
        if(mask.mask){
            NSUInteger sizePix = mask.imageStack.numberOfPixels;
            int * res = (int *)calloc(sizePix, sizeof(int));
            for (NSInteger i = 0; i < sizePix; i++)
                res[i] = mask.mask[i];
            st->mask = res;
            st->width = mask.imageStack.width;
            st->height = mask.imageStack.height;
            return st;
        }
    }
    if([node isMemberOfClass:[IMCPixelMap class]]){
        IMCPixelMap *map = (IMCPixelMap *)node;
        if(map.stackData){
            if(map.stackData[0] && map.stackData[1]){
                NSUInteger sizePix = map.imageStack.numberOfPixels;
                int * res = (int *)calloc(sizePix, sizeof(int));
                for (NSInteger i = 0; i < sizePix; i++)
                    if(map.stackData[1][i] >= certainty)
                        res[i] = (int)map.stackData[0][i];
                st->mask = res;
                st->width = map.imageStack.width;
                st->height = map.imageStack.height;
                return st;
            }
        }
    }
    
    return NULL;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//TODO
        [[NSApplication sharedApplication] runModalForWindow:self.window];
        
    });
    self.arrSegmentationMasks = @[].mutableCopy;
    self.arrAllMasks = @[].mutableCopy;
}
- (void)windowWillClose:(NSNotification *)notification {
    [[NSApplication sharedApplication] stopModal];
}
-(instancetype)init{
    return [self initWithWindowNibName:NSStringFromClass([IMCCombineMasks class]) owner:self];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [[self.delegate allStacks]count];
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return [(IMCImageStack *)[self.delegate allStacks][row]itemName];
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    NSInteger rowIndex = self.stacksTableView.selectedRowIndexes.firstIndex;
    if(self.stacksTableView.selectedRowIndexes.count > 1)
       [self.stacksTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
    if(rowIndex == NSNotFound)
        return;
    self.arrSegmentationMasks = @[].mutableCopy;
    self.arrAllMasks = @[].mutableCopy;

    for (IMCNodeWrapper *child in [(IMCImageStack *)[self.delegate allStacks][rowIndex]children]) {
        if([child isMemberOfClass:[IMCPixelClassification class]]){
            IMCPixelClassification *mask = (IMCPixelClassification *)child;
            if(mask.isCellMask)
                [self.arrSegmentationMasks addObject:mask];
            else
                [self.arrAllMasks addObject:mask];
        }
        if([child isMemberOfClass:[IMCPixelMap class]]){
            IMCPixelClassification *map = (IMCPixelClassification *)child;
                [self.arrAllMasks addObject:map];
        }
    }
    NSMutableArray *titlesArrSegmentationMasks = @[].mutableCopy;
    NSMutableArray *titlesArrAllMaks = @[].mutableCopy;
    for (IMCNodeWrapper *node in self.arrSegmentationMasks)
        [titlesArrSegmentationMasks addObject:[NSString stringWithFormat:@"%@ | %@", node.itemName, node.itemSubName]];
    for (IMCNodeWrapper *node in self.arrAllMasks)
        [titlesArrAllMaks addObject:[NSString stringWithFormat:@"%@ | %@", node.itemName, node.itemSubName]];
    
    [General addArrayOfStrings:titlesArrSegmentationMasks toNSPopupButton:self.originMask noneAtBeggining:NO];
    [General addArrayOfStrings:titlesArrAllMaks toNSPopupButton:self.targetMask noneAtBeggining:NO];
    
    [self refresh];
}
-(void)setupScrollView:(IMCScrollView *)scroll forMask:(IMCNodeWrapper *)maskOrMap{
    IMCImageStack *stack;
    if([maskOrMap isMemberOfClass:[IMCPixelMap class]])
        stack = (IMCImageStack *)maskOrMap;
    if([maskOrMap isMemberOfClass:[IMCPixelClassification class]])
        stack = [(IMCPixelClassification *)maskOrMap imageStack];
    //= [self.delegate allStacks][self.stacksTableView.selectedRow];
    if(stack){
        CGImageRef ref = [[IMCImageGenerator imageForImageStacks:@[stack].mutableCopy
                                                         indexes:maskOrMap == stack ?@[@0]:@[]
                                                withColoringType:0
                                                    customColors:nil
                                               minNumberOfColors:1
                                                           width:stack.width
                                                          height:stack.height
                                                  withTransforms:NO blend:kCGBlendModeScreen
                                                        andMasks:maskOrMap == stack ? @[]:@[(IMCPixelClassification *)maskOrMap]
                                                 andComputations:nil
                                                      maskOption:MASK_FULL
                                                        maskType:MASK_ALL_CELL
                                                 maskSingleColor:0
                                                 isAlignmentPair:NO
                                                     brightField:NO]CGImage];
        if(ref)
            scroll.imageView.image = [NSImage imageWithRef:ref];
    }
}
-(float *)IdMask:(IMCPixelClassification *)mask withMask:(int *)newIds{
    float * reIdedMask = (float *)calloc(mask.numberOfSegments, sizeof(float));
    NSInteger size = mask.imageStack.numberOfPixels;
    for (NSInteger i = 0; i < size; i ++) {
        if(mask.mask[i] != 0 && newIds[i] != 0)
            reIdedMask[abs(mask.mask[i]) - 1] = newIds[i];
    }
    return reIdedMask;
}

-(void)refresh:(id)sender{
    [self refresh];
}
-(BOOL)trueDistanceFalseExtract{
    return (self.calculation.indexOfSelectedItem < 2);
}
-(BOOL)trueDistanceFalseProximity{
    return (self.calculation.indexOfSelectedItem == 0);
}
-(BOOL)trueContainedFalseExcluded{
    return (self.calculation.indexOfSelectedItem == 2);
}
-(void)refresh{
    
    self.tolerance.hidden = (self.calculation.indexOfSelectedItem < 2);
    self.toleranceLabel.hidden = (self.calculation.indexOfSelectedItem < 2);
    self.captureId.hidden = (self.calculation.indexOfSelectedItem != 2);
    self.certaintyField.stringValue = [@"Certainty " stringByAppendingFormat:@"%.2f", self.certaintySlider.floatValue];
    BOOL showCerts = [self.arrAllMasks[[self.targetMask indexOfSelectedItem]] isMemberOfClass:[IMCPixelMap class]];
    self.certaintySlider.hidden = !showCerts;
    self.certaintyField.hidden = !showCerts;
    
    if([self.originMask indexOfSelectedItem] >= 0 && [self.targetMask indexOfSelectedItem] >= 0){
        
        IMCPixelClassification *maskOr = self.arrSegmentationMasks[self.originMask.indexOfSelectedItem];
        IMCNodeWrapper *maskTar = self.arrAllMasks[self.targetMask.indexOfSelectedItem];
        PixelStruct *targetPixStruct = [self structFromObject:maskTar withCertainty:self.certaintySlider.floatValue];
        
        NSArray *arr = @[@[maskOr, self.originScroll],@[maskTar, self.targetScroll]];
        
        for (NSArray *sub in arr) {
            IMCNodeWrapper *mask = sub.firstObject;
            IMCScrollView *scroll = sub.lastObject;
            if(!mask.isLoaded){
                [mask loadLayerDataWithBlock:^{
                    [self setupScrollView:scroll forMask:mask];
                }];
            }else{
                [self setupScrollView:scroll forMask:mask];
            }
        }
        if(maskOr.isLoaded && maskTar.isLoaded && maskOr != maskTar && targetPixStruct){
            if(results)
                free(results);
            results = NULL;
            if(![self trueDistanceFalseExtract]){
                
                int * cast = [IMCMasks extractFromMask:maskOr.mask withMask:targetPixStruct->mask width:maskOr.imageStack.width height:maskOr.imageStack.height tolerance:self.tolerance.floatValue exclude:(self.calculation.indexOfSelectedItem == 3) filterLabel:self.whichLabels.selectedSegment == 1?self.specificlabel.intValue:NSNotFound];
                
                if(self.captureId.state == NSOnState && self.calculation.indexOfSelectedItem == 2)
                    [IMCMasks idMask:cast target:targetPixStruct->mask size:maskOr.imageStack.size];
                else
                    for (NSInteger i = 0; i < maskOr.imageStack.numberOfPixels; i++)
                        if(cast[i] != 0)
                            cast[i] = 1;
                
                CGImageRef maskImage = [IMCImageGenerator colorMask:cast numberOfColors:20 singleColor:nil width:maskOr.imageStack.width height:maskOr.imageStack.height];
                self.outputScroll.imageView.image = [NSImage imageWithRef:maskImage];
                
                results = [self IdMask:maskOr withMask:cast];
            }else{
                IMCComputationOnMask *compOr = maskOr.computationNodes.firstObject;
                if(!compOr){
                    [self calculateFeaturesForMask:maskOr andBlock:^{
                        IMCComputationOnMask *newCompOr = maskOr.computationNodes.firstObject;
                        [self executeDistanceCalcForCalculation:newCompOr pixStructTarget:targetPixStruct];
                    }];
                }else{
                    [self executeDistanceCalcForCalculation:compOr pixStructTarget:targetPixStruct];
                }
            }
        }
    }
}

-(void)addResults:(id)sender{
    
    NSString *tit;
    
    IMCPixelClassification *maskOr = self.arrSegmentationMasks[self.originMask.indexOfSelectedItem];
    IMCNodeWrapper *maskTar = self.arrAllMasks[self.targetMask.indexOfSelectedItem];
    
    float * copy = (float *)calloc(maskOr.numberOfSegments, sizeof(float));
    NSInteger cells = maskOr.numberOfSegments;
    for (NSInteger i = 0; i < cells; i++)
        copy[i] = results[i];
    
    BOOL showCerts = [self.arrAllMasks[[self.targetMask indexOfSelectedItem]] isMemberOfClass:[IMCPixelMap class]];
    NSString *filt = self.specificlabel.integerValue == NSNotFound || !showCerts ?@"":[NSString stringWithFormat:@"f(%li-%f", self.specificlabel.integerValue, self.certaintySlider.floatValue];
    
    if([self trueDistanceFalseExtract]){
        tit = [NSString stringWithFormat:@"%@%@%@", [self trueDistanceFalseProximity]?@"Dist_":@"Prox_", maskTar.itemName, filt];
    }
    
    if(![self trueDistanceFalseExtract]){
        tit = [NSString stringWithFormat:@"%@%@_%.3f%@", [self trueContainedFalseExcluded]?@"In_":@"NotIn_", maskTar.itemName, self.tolerance.floatValue, filt];
    }
    
    
    [maskOr initComputations];
    IMCComputationOnMask *comp = maskOr.computationNodes.firstObject;
    if(comp)
        [comp addBuffer:copy withName:tit atIndex:NSNotFound];
    else
    {
        [self calculateFeaturesForMask:maskOr andBlock:^{
            IMCComputationOnMask *newComp = maskOr.computationNodes.firstObject;
            [newComp addBuffer:copy withName:tit atIndex:NSNotFound];
        }];
    }
}
-(void)calculateFeaturesForMask:(IMCPixelClassification *)mask andBlock:(void(^)())block{
    NSInteger sure = [General runAlertModalAreYouSureWithMessage:@"You need to extract the mask features first. Would you like to proceed?"];
    if(sure == NSAlertFirstButtonReturn){
        dispatch_queue_t feat = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
        dispatch_async(feat, ^{
            [mask extractDataForMask:[General cellComputations] processedData:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(block)block();
            });
        });
    }
}
-(void)executeDistanceCalcForCalculation:(IMCComputationOnMask *)compOr pixStructTarget:(PixelStruct *)pixStruct{
    if(!compOr.isLoaded)
        [compOr loadLayerDataWithBlock:nil];
    while (!compOr.isLoaded);
    
    results = [IMCMasks distanceToMasksEuclidean:[compOr xCentroids] yCentroids:[compOr yCentroids] destMask:pixStruct->mask max:compOr.mask.numberOfSegments width:compOr.mask.imageStack.width height:compOr.mask.imageStack.height filterLabel:self.whichLabels.selectedSegment == 1?self.specificlabel.intValue:NSNotFound];
    
    if(self.calculation.indexOfSelectedItem == 1)
        [IMCMasks invertToProximity:results cells:compOr.mask.numberOfSegments];
    
    float * piz = [compOr createImageForMaskWithCellData:results maskOption:MASK_NO_BORDERS maskType:MASK_ALL_CELL maskSingleColor:nil];
    
    float max = .0f;
    for (NSInteger i = 0; i < compOr.mask.numberOfSegments; i++)
        if(results[i] > max)
            max = results[i];
    
    
    NSInteger size = compOr.mask.imageStack.numberOfPixels;
    UInt8 * trans = (UInt8 *)calloc(size, sizeof(UInt8));
    for (NSInteger i = 0; i < size; i++)
        trans[i] = (UInt8)((piz[i]/max) * 255.0f);
    CGImageRef maskImage = [IMCImageGenerator imageFromCArrayOfValues:trans color:nil width:compOr.mask.imageStack.width height:compOr.mask.imageStack.height startingHueScale:170 hueAmplitude:170 direction:NO ecuatorial:NO brightField:NO];
    self.outputScroll.imageView.image = [NSImage imageWithRef:maskImage];
    if(trans)free(trans);
    if(piz)free(piz);
}

#pragma mark changed which labels

-(void)changedWhichLabels:(NSSegmentedControl *)sender{
    self.specificlabel.hidden = (sender.selectedSegment == 0);
}
-(void)chosenLabel:(NSTextField *)sender{
    if(!isnan([sender integerValue]) || sender.integerValue != NSNotFound)
        [self refresh];
}
-(void)dealloc{
    if(results)
        free(results);
}
@end
