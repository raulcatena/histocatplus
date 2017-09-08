//
//  IMCPixelTrainer.m
//  3DIMC
//
//  Created by Raul Catena on 3/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelTrainer.h"
#import "IMCPixelTraining.h"
#import "IMCButtonLayer.h"
#import "IMCImageGenerator.h"
#import "NSImage+OpenCV.h"
#import "IMCRandomForests.h"
#import "IMCPixelMap.h"

@interface IMCPixelTrainer()
@property (nonatomic, strong) IMCRandomForests *randomForests;
@end

@implementation IMCPixelTrainer

#pragma mark lifetime and general

-(void)setStack:(IMCImageStack *)stack{
    self.mapPrediction = nil;
    _stack = stack;
}
-(void)updateTrainingSettings{
    [self preparePreviousTrainings:@[self.trainingNodes.firstObject]];
}
-(BOOL)preparePreviousTrainings:(NSArray <IMCPixelTraining *>*)trainings{
    
    //Check all trainings are exactly equivalent
    if(trainings.count > 1){
        IMCPixelTraining *first = trainings.firstObject;
        for (int i = 1; i<trainings.count; i++) {
            IMCPixelTraining *other = trainings[i];
            
            //Same number of channels
            if(other.imageStack.channels.count != first.imageStack.channels.count)
                return NO;
            
            //Same number of channels for training
            NSArray *dicsFirst = first.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS];
            NSArray *dicsOther = other.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS];
            
            if(dicsOther.count != dicsFirst.count)return NO;
            
            //Same exact training options
            for (int j = 0; j < dicsFirst.count; j++) {
                
                NSDictionary *dicFirst = dicsFirst[j];
                NSDictionary *dicOther = dicsOther[j];
                
                if(![dicFirst.allKeys.firstObject isEqualToString:dicOther.allKeys.firstObject])
                    return NO;
                if([dicFirst.allValues.firstObject count] != [dicOther.allValues.firstObject count])
                    return NO;
                for (int m = 0; m < [dicFirst.allValues.firstObject count]; m++)
                    if(dicFirst.allValues.firstObject[m] != dicOther.allValues.firstObject[m])
                        return NO;
            }
        }
    }

    //If gone through check, setup the items for hyerachy. This maps to the OutlineView in the VC
    for (NSDictionary *dic in trainings.firstObject.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS]) {
        NSInteger index = [dic.allKeys.firstObject integerValue];
        if(index < self.options.count){
            IMCButtonLayer *parent = [self.options objectAtIndex:index];
            for (NSNumber *num in dic.allValues.firstObject) {
                
                BOOL found = NO;
                for(IMCButtonLayer *child in parent.children){
                    if(child.type == num.integerValue)
                        found = YES;
                }
                if(found == NO){
                    IMCButtonLayer *lay = [[IMCButtonLayer alloc]init];
                    lay.type = (PixelLayerType)num.integerValue;
                    lay.parent = parent;
                }
                if(![self.useChannels containsObject:parent])
                    [self.useChannels addObject:parent];
            }
        }
    }
    
    self.labels = trainings.firstObject.trainingLabels.mutableCopy;
    return YES;
}

-(BOOL)bodyOfInitWithStack:(IMCImageStack *)stack andTrainings:(NSArray <IMCPixelTraining *>*)trainings{
    
    BOOL success = YES;
    
    if(trainings.firstObject.imageStack.channels.count != stack.channels.count)
        success = NO;
    
    self.theHash = self.trainingNodes.firstObject.itemHash;
    self.useChannels = @[].mutableCopy;
    self.options = @[].mutableCopy;
    
    for(int i = 0; i < stack.channels.count; i++){
        IMCButtonLayer *lay = [[IMCButtonLayer alloc]init];
        lay.channel = [stack.channels[i]copy];
        [self.options addObject:lay];
    }
    
//    if(trainings.count == 1)
//        for (IMCPixelMap *map in trainings.firstObject.imageStack.pixelMaps)
//            if(map.whichTraining == trainings.firstObject)
//                self.mapPrediction = map;
    
    if(success)
        success = [self preparePreviousTrainings:trainings];
    
    if(success){
        self.stack = stack;
        self.trainingNodes = trainings;
    }
    
    return success;
}

-(instancetype)initWithStack:(IMCImageStack *)stack andTrainings:(NSArray <IMCPixelTraining *>*)trainings{
    self = [self init];
    if(self){
        BOOL success = [self bodyOfInitWithStack:stack andTrainings:trainings];
        if(!success)
            return nil;
    }
    return self;
}

-(NSString *)theHash{
    if(!_theHash){
        NSMutableString *str = @"".mutableCopy;
        for (IMCPixelTraining *train in self.trainingNodes)
            [str appendString:train.itemHash];
        _theHash = [NSString stringWithString:str];
    }
    return _theHash;
}

-(void)toogleOption:(IMCButtonLayer *)lay{
    
    if(!lay.parent){
        if ([self.useChannels containsObject:lay]){
            
            [self.useChannels removeObject:lay];
        }
        else
        {
            if(!lay.children){
                for(int i = 0; i < 10; i++){
                    IMCButtonLayer *child = [[IMCButtonLayer alloc]init];
                    child.parent = lay;
                    switch (i) {
                        case 0:
                            child.type = PIXEL_LAYER_DIRECT;
                            break;
                        case 1:
                            child.type = PIXEL_LAYER_GB_3;
                            break;
                        case 2:
                            child.type = PIXEL_LAYER_GB_5;
                            break;
                        case 3:
                            child.type = PIXEL_LAYER_GB_7;
                            break;
                        case 4:
                            child.type = PIXEL_LAYER_LOG_3;
                            break;
                        case 5:
                            child.type = PIXEL_LAYER_LOG_5;
                            break;
                        case 6:
                            child.type = PIXEL_LAYER_LOG_7;
                            break;
                        case 7:
                            child.type = PIXEL_LAYER_GAUSSIAN_GRAD_5;
                            break;
                        case 8:
                            child.type = PIXEL_LAYER_GAUSSIAN_GRAD_7;
                            break;
                        case 9:
                            child.type = PIXEL_LAYER_CANNY_7;
                            break;
                        default:
                            break;
                    }
                }
            }
            [self.useChannels addObject:lay];
        }
    }
    [self saveTrainingSettingsSegmentation:self.trainingNodes.firstObject];
}

-(NSImage *)rawImageForNode:(IMCButtonLayer *)node inStack:(IMCImageStack *)stack{
    IMCButtonLayer *parent = node.parent?node.parent:node;
    NSNumber *indexNode = [NSNumber numberWithInteger:[self.options indexOfObject:parent]];
    
    NSImage * image = [IMCImageGenerator imageForImageStacks:@[stack].mutableCopy
                                                     indexes:@[indexNode]
                                            withColoringType:0
                                                customColors:@[[NSColor whiteColor]]
                                           minNumberOfColors:1
                                                       width:stack.width
                                                      height:stack.height
                                              withTransforms:NO
                                                       blend:kCGBlendModeScreen
                                                    andMasks:nil
                                             andComputations:nil
                                                  maskOption:NULL
                                                    maskType:MASK_ALL_CELL
                                             maskSingleColor:[NSColor whiteColor]
                                             isAlignmentPair:NO
                                                 brightField:NO];
    return image;
}

-(NSImage *)imageForNode:(IMCButtonLayer *)node inStack:(IMCImageStack *)stack{
    NSImage *image = [self rawImageForNode:node inStack:stack];
    
    if(node.parent){
        if(node.type > PIXEL_LAYER_DIRECT && node.type < PIXEL_LAYER_LOG_3)
            image = [image gaussianBlurred:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        
        if(node.type > PIXEL_LAYER_GB_51 && node.type < PIXEL_LAYER_CANNY_3)
            image = [image log:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        
        if(node.type >= PIXEL_LAYER_CANNY_3  && node.type < PIXEL_LAYER_GAUSSIAN_GRAD_3)
            image = [image canny:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        
        if(node.type >= PIXEL_LAYER_GAUSSIAN_GRAD_3)
            image = [image gaussianGradient:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
    }
    return image;
}
-(UInt8 *)bufferForNode:(IMCButtonLayer *)node inStack:(IMCImageStack *)stack{
    NSImage *image = [self rawImageForNode:node inStack:stack];
    
    UInt8 *data = NULL;
    if(node.parent){
        if(node.type > PIXEL_LAYER_DIRECT && node.type < PIXEL_LAYER_LOG_3){
            data = [image dataGaussianBlurred:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        }
        else if(node.type > PIXEL_LAYER_GB_51 && node.type < PIXEL_LAYER_CANNY_3){
            data = [image dataLog:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        }else if(node.type >= PIXEL_LAYER_CANNY_3 && node.type < PIXEL_LAYER_GAUSSIAN_GRAD_3){
            data = [image dataCanny:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        }else if(node.type >= PIXEL_LAYER_GAUSSIAN_GRAD_3){
            data = [image dataGaussianGradient:[[[[node nameForOption]componentsSeparatedByString:@"x"]lastObject]intValue]];
        }else{
            data = [image dataGaussianBlurred:1];
        }
    }
    return data;
}

-(NSMutableArray *)imageRefsInScopeForStack:(IMCImageStack *)stack{
    NSMutableArray *refs = @[].mutableCopy;
    for(IMCButtonLayer *par in self.useChannels){
        for (IMCButtonLayer *child in par.children) {
            NSImage *image = [self imageForNode:child inStack:stack];
            [refs addObject:(__bridge id)image.CGImage];
        }
    }
    return refs;
}
-(UInt8 **)buffersInScopeForStack:(IMCImageStack *)stack{
    UInt8 * buffs[[self numberRefsInScope]];
    NSInteger counter = 0;
    for(IMCButtonLayer *par in self.useChannels)
        for (IMCButtonLayer *child in par.children) {
            buffs[counter] = [self bufferForNode:child inStack:stack];
            counter++;
        }

    return NULL;
}

-(NSInteger)numberRefsInScope{
    NSInteger counter = 0;
    for(IMCButtonLayer *par in self.useChannels)
        counter+= par.children.count;
    return counter;
}

-(BOOL)trainRandomForests{
    //Pre. Calculate number of pixels trained
    NSInteger counter = 0;
    NSInteger chanCount = 0;
    NSInteger labelsCount = 0;
    
    NSMutableArray *scopeImages = @[].mutableCopy;
    for (IMCPixelTraining *train in self.trainingNodes) {
        NSLog(@"Node");
        if(!train.imageStack.isLoaded)
            [train.imageStack loadLayerDataWithBlock:nil];
        while (!train.imageStack.isLoaded);
        NSArray *refs = [self imageRefsInScopeForStack:train.imageStack];
        if(chanCount == 0)chanCount = refs.count;
        if(chanCount != refs.count){
            [General runAlertModalWithMessage:@"Can't continue. Trainings have different amount of features"];
            return NO;
        }
        if(labelsCount == 0)
            labelsCount = self.labels.count;
        if(labelsCount != self.labels.count){
            [General runAlertModalWithMessage:@"Can't continue. Trainings have different amount of labels"];
            return NO;
        }
        [scopeImages addObjectsFromArray:refs];
        
        NSInteger subPix = train.imageStack.numberOfPixels;
        for(int j = 0; j < subPix; j++)
            if(train.trainingBuffer[j] > 0)
                counter++;
        NSLog(@"Trained %li", counter);
    }
    
    
    if(chanCount == 0 || labelsCount == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            [General runAlertModalWithMessage:@"Can't continue. No features or labels defined"];
        });
        return NO;
    }
    
    //First. Allocate arrays to pass to the random forests algorithm
    float * filteredChannelsAndClassTraining = (float *)calloc((chanCount + 1) * counter, sizeof(float));
    
    UInt8 * allData[scopeImages.count];
    for (int i = 0; i < scopeImages.count; i++) {
        CGImageRef ref = (__bridge CGImageRef)[scopeImages objectAtIndex:i];
        UInt8 * data = [IMCImageGenerator bufferForImageRef:ref];
        allData[i] = data;
    }
    NSLog(@"Scope images count %li chan count %li", scopeImages.count, chanCount);
    //Prepare training buffer
    counter = 0;
    
    NSInteger trainCount = 0;
    for (IMCPixelTraining *train in self.trainingNodes) {
        NSInteger subPix = train.imageStack.numberOfPixels;
        for(NSInteger i = 0; i < subPix; i++){
            if(train.trainingBuffer[i] > 0){//It's a training pixel
                //printf(" %u", train.trainingBuffer[i]);
                for (int j = 0; j < chanCount; j++)//Add value
                    filteredChannelsAndClassTraining[counter * (chanCount + 1) + j] = (float)allData[trainCount * chanCount + j][i * 4];
                
                //If is training I need to specify the class
                filteredChannelsAndClassTraining[counter * (chanCount + 1) + chanCount] = (float)train.trainingBuffer[i];
                counter++;
            }
        }
        trainCount++;
    }
    NSLog(@"Done training %li", counter);
    
    self.randomForests = [[IMCRandomForests alloc]init];
    self.randomForests.trainingData = filteredChannelsAndClassTraining;
    self.randomForests.numberOfTrainingSamples = (int)counter;
    self.randomForests.numberOfClasses = (int)labelsCount;
    self.randomForests.attributesPerSample = (int)chanCount;
    
    for (int i =0; i < scopeImages.count; i++) {
        CGImageRef ref = (__bridge CGImageRef)[scopeImages objectAtIndex:i];
        if(ref)
            CFRelease(ref);
        
        if(allData[i])
            free(allData[i]);
    }
    return YES;
}

-(void)loadDataInRRFF{
    //Prepare test buffer
    NSInteger pixels = self.stack.numberOfPixels;
    NSInteger chanCount = [self numberRefsInScope];
    
    BOOL wasLoaded = self.stack.isLoaded;
    if(!self.stack.isLoaded)[self.stack loadLayerDataWithBlock:nil];
    while (!self.stack.isLoaded);
    
    NSArray *scopeProbando = [self imageRefsInScopeForStack:self.stack];
    UInt8 * allDataProbando[scopeProbando.count];
    for (int i = 0; i < scopeProbando.count; i++) {
        CGImageRef ref = (__bridge CGImageRef)[scopeProbando objectAtIndex:i];
        UInt8 * data = [IMCImageGenerator bufferForImageRef:ref];
        allDataProbando[i] = data;
        CFRelease(ref);
    }
    float * filteredChannelsAndClassProbando = (float *)calloc((chanCount + 1) * pixels, sizeof(float));
    for(NSInteger i = 0; i < pixels; i++)
        for (int j = 0; j < chanCount; j++)
            filteredChannelsAndClassProbando[i * (chanCount + 1) + j] = (float)allDataProbando[j][i * 4];
        
    
    for(int i = 0; i < scopeProbando.count; i++)
        if(allDataProbando[i] != NULL)
            free(allDataProbando[i]);
    
    if(self.randomForests.testingData != NULL)
        free(self.randomForests.testingData);
    self.randomForests.testingData = filteredChannelsAndClassProbando;
    self.randomForests.numberOfTestingSamples = (int)pixels;
    if(self.randomForests.outputProbabilities != NULL)
        free(self.randomForests.outputProbabilities);
    self.randomForests.outputProbabilities = (float *)calloc(pixels * self.labels.count, sizeof(float));
    if(!wasLoaded)[self.stack unLoadLayerDataWithBlock:nil];
}

-(void)newMap{
    self.mapPrediction = [[IMCPixelMap alloc]init];

    self.mapPrediction.stackData = (float **)calloc(1, sizeof(float *));
    self.mapPrediction.width = self.stack.width;
    self.mapPrediction.height = self.stack.height;
    self.mapPrediction.isSegmentation = self.isSegmentation;
    self.mapPrediction.jsonDictionary[JSON_DICT_ITEM_HASH] = [IMCUtils randomStringOfLength:20];
    
    NSString *savePath = [self.stack.workingFolderRealative stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"%@_%@_pred.tiff", self.theHash.copy, self.isSegmentation?@"seg":@""]];
    
    self.mapPrediction.jsonDictionary[JSON_DICT_ITEM_RELPATH] = savePath;
    self.mapPrediction.jsonDictionary[JSON_DICT_ITEM_NAME] = self.theHash.copy;
    self.mapPrediction.jsonDictionary[JSON_DICT_ITEM_NAME] = [self.theHash.copy stringByAppendingString:@" training based map"];
    self.mapPrediction.jsonDictionary[JSON_DICT_PIXEL_MAP_FOR_SEGMENTATION] = [NSNumber numberWithBool:self.isSegmentation];
}

-(void)classifyPixels{
    [self.randomForests execute];
    
    NSInteger pixels = self.stack.numberOfPixels;
    NSInteger chanCount = [self numberRefsInScope];
    
    for (IMCPixelMap *map in self.stack.pixelMaps) {
        if([map.itemName isEqualToString:self.theHash])
            if(map.whichTraining == self.trainingNodes.firstObject)
                self.mapPrediction = map;
    }
    
    if(!self.mapPrediction)
        [self newMap];

    if(!self.mapPrediction.parent)
        self.mapPrediction.parent = self.stack;
    
    if(self.mapPrediction.stackData[0])
        free(self.mapPrediction.stackData[0]);
    if(self.mapPrediction.stackData[1])
        free(self.mapPrediction.stackData[1]);
    
    self.mapPrediction.stackData = (float **)calloc(2, sizeof(float *));
    
    NSInteger pix = self.stack.numberOfPixels;
    self.mapPrediction.stackData[0] = (float *)calloc(pix, sizeof(float));
    self.mapPrediction.stackData[1] = (float *)calloc(pix, sizeof(float));
    for(NSInteger i = 0; i < pixels; i++){
        float val = self.randomForests.testingData[i * (chanCount + 1) + chanCount];
        float classPred = floorf(val);
        float prob = val - classPred;
        self.mapPrediction.stackData[0][i] = classPred;
        self.mapPrediction.stackData[1][i] = prob;
    }
}

-(void)classifyPixelsAllSteps{
    if([self trainRandomForests]){
        [self loadDataInRRFF];
        [self classifyPixels];
    }
}


#pragma mark saving functions

-(NSArray *)arrayTrainingOptions{
    NSMutableArray *arr = @[].mutableCopy;
    
    for (IMCButtonLayer *lay in self.useChannels) {
        NSMutableArray *arrChan = @[].mutableCopy;
        NSMutableDictionary *chan = @{
                                      [NSString stringWithFormat:@"%li",
                                       [self.stack.channels indexOfObject:lay.channel]]:
                                          arrChan
                                      }.mutableCopy;
        for(IMCButtonLayer *chil in lay.children){
            [arrChan addObject:[NSNumber numberWithInteger:(NSInteger)[chil type]]];
        }
        [arr addObject:chan];
    }
    return arr;
}


-(NSString *)pathForTrainingTiffSegmentation:(BOOL)segmentation{
    return [NSString stringWithFormat:@"%@/%@_%@_train.tiff",
            self.stack.workingFolderRealative,
            self.theHash.copy, segmentation?@"seg":@""];
}

-(void)prepTrainingNode:(IMCPixelTraining *)node{
    if(!node.relativePath)
        node.relativePath = [self pathForTrainingTiffSegmentation:[self isSegmentation]];
    
//    if(!node.jsonDictionary[JSON_DICT_ITEM_HASH])
//        node.jsonDictionary[JSON_DICT_ITEM_HASH] = self.theHash.copy;
    
    node.jsonDictionary[JSON_DICT_PIXEL_TRAINING_IS_SEGMENTATION] = [NSNumber numberWithBool:[self isSegmentation]];
    node.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LABELS] = self.labels;
    node.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS] = [self arrayTrainingOptions];
}

-(void)saveTrainingSettingsSegmentation:(IMCPixelTraining *)training{
    [self prepTrainingNode:training];
}

-(void)saveTrainingMask:(IMCPixelTraining *)training{
    [training.imageStack.fileWrapper checkAndCreateWorkingFolder];
    
    CGImageRef trainingImg = [IMCImageGenerator whiteImageFromCArrayOfValues:training.trainingBuffer width:training.imageStack.width height:training.imageStack.height];
    
    NSImage *image = [[NSImage alloc]initWithCGImage:trainingImg size:self.stack.size];
    
    NSData *data = [image TIFFRepresentation];
    NSString *path = [NSString stringWithFormat:@"%@/%@_%@_train.tiff",
                      [self.stack workingFolder],
                      self.theHash.copy, training.isSegmentation?@"seg":@""];
    
    NSLog(@"path save training mask %@", path);
    
    [data writeToFile:path atomically:YES];
    
    CFRelease(trainingImg);
}

@end
