//
//  IMCComputationOnMask.m
//  3DIMC
//
//  Created by Raul Catena on 2/18/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCComputationOnMask.h"
#import "IMCPixelClassification.h"
#import "NSArray+Statistics.h"
#import "IMCMasks.h"
#import "IMCImageGenerator.h"
#import "IMCFileWrapper.h"
#import "NSMutableArrayAdditions.h"
#import "flock.h"

@class IMCMaskTraining;

@interface IMCComputationOnMask(){
    BOOL computed;
    
    UInt8 ** cachedValues;
    float ** cachedSettings;
}

@property (nonatomic, strong) NSMutableArray *lastOptions;
@property (nonatomic, strong) NSMutableArray *lastTypes;
@property (nonatomic, strong) NSMutableDictionary *statsComputed;
@end

@implementation IMCComputationOnMask

-(NSString *)itemName{
    return self.mask.itemName;
}
-(NSString *)itemSubName{
    return self.mask.itemSubName;
    return [@"features " stringByAppendingString:self.mask.itemHash];/////
}
-(NSMutableArray *)trainingNodes{
    return [self.children filterClass:NSStringFromClass([IMCMaskTraining class])].mutableCopy;
}
-(IMCFileWrapper *)fileWrapper{
    return self.mask.imageStack.fileWrapper;
}
-(void)setJsonDictionary:(NSMutableDictionary *)jsonDictionary{
    [super setJsonDictionary:jsonDictionary];
    [self initAllChildrenOfStack];
}
-(void)initAllChildrenOfStack{
    
    NSArray *keys = @[JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS];
    for (NSString *key in keys) {
        for (NSMutableDictionary *trainJson in [self.jsonDictionary[key]copy]) {
            
            BOOL found = NO;
            for (IMCNodeWrapper * childStack in self.children) {
                if(childStack.jsonDictionary == trainJson)
                    found = YES;
            }
            if(found == NO){
                if(trainJson.allKeys.count == 0)
                    [self.jsonDictionary[key] removeObject:trainJson];
                else
                {
                    IMCNodeWrapper *child;
                    if([key isEqualToString:JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS])
                        child = [[IMCMaskTraining alloc]init];
                    child.jsonDictionary = trainJson;//Important this first
                    child.parent = self;
                }
            }
        }
    }
}
-(void)setMask:(IMCPixelClassification *)mask{
    if(!mask){
        if([self.mask.computationNodes containsObject:self])
            [self.mask.computationNodes removeObject:self];
    }else{
        if(!self.mask.computationNodes)self.mask.computationNodes = @[].mutableCopy;
        if(![mask.computationNodes containsObject:self])
            [mask.computationNodes addObject:self];
    }
    _mask = mask;
}

-(void)setParent:(IMCNodeWrapper *)parent{
    [super setParent:parent];
    [self setMask:(IMCPixelClassification *)parent];
}

-(NSInteger)segmentedUnits{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_UNITS]){
        NSInteger units = [self.mask numberOfSegments];
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_UNITS] = [NSNumber numberWithInteger:units];
    }
    return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_UNITS]integerValue];
}
-(NSMutableArray *)channels{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS])
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS] = @[].mutableCopy;
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS];
}
-(IMCChannelWrapper *)wrappedChannelAtIndex:(NSInteger)index{
    IMCChannelWrapper *chann = [[IMCChannelWrapper alloc]init];
    chann.index = index;
    chann.node = self;
    return chann;
}
-(NSMutableArray *)originalChannels{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS])
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS] = @[].mutableCopy;
    if([self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS]count] != self.channels.count){
        NSMutableArray *newArr = @[].mutableCopy;
        for (NSString *chan in self.channels)
            [newArr addObject:chan.mutableCopy];
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS] = newArr;
    }
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS];
}

-(NSMutableDictionary *)vanillaSettings{
    return @{
             JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET:[NSNumber numberWithFloat:1.0f],
             JSON_DICT_CHANNEL_SETTINGS_OFFSET:[NSNumber numberWithFloat:.0f],
             JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER:[NSNumber numberWithFloat:1.0f],
             JSON_DICT_CHANNEL_SETTINGS_SPF:[NSNumber numberWithFloat:.0f],
             JSON_DICT_CHANNEL_SETTINGS_TRANSFORM:[NSNumber numberWithFloat:.0f]
             }.mutableCopy;
}
-(NSMutableArray *)channelSettings{
    NSMutableArray *settings = self.jsonDictionary[JSON_DICT_IMAGE_CHANNEL_SETTINGS];
    if(!settings){
        NSMutableArray *arr = @[].mutableCopy;
        for (int i = 0; i < self.channels.count; i++) {
            [arr addObject:[self vanillaSettings]];
        }
        [self setChannelSettings:arr];
    }
    if(settings.count < self.channels.count){
        NSMutableArray *arr = @[].mutableCopy;
        for (NSInteger i = settings.count; i < self.channels.count; i++) {
            [arr addObject:[self vanillaSettings]];
        }
        [settings addObjectsFromArray:arr];
    }
    return self.jsonDictionary[JSON_DICT_IMAGE_CHANNEL_SETTINGS];
}
-(void)setChannelSettings:(NSMutableArray *)channelSettings{
    [self.jsonDictionary setValue:channelSettings forKey:JSON_DICT_IMAGE_CHANNEL_SETTINGS];
}

-(void)loadLayerDataWithBlock:(void (^)())block{
    if(!self.mask.isLoaded)
        [self.mask loadLayerDataWithBlock:nil];
    while (!self.mask.isDual);
    
    if(!self.isLoaded)
        [self open];
    if(!self.isLoaded)
        return;
    [super loadLayerDataWithBlock:block];
}
-(void)unLoadLayerDataWithBlock:(void (^)())block{
    [self release_computedData];
    [self clearCacheBuffers];
    [super unLoadLayerDataWithBlock:block];
}

-(void)prepData{
    
    [self release_computedData];
    
    NSInteger countChannels = self.channels.count;
    self.computedData = malloc(countChannels * sizeof(float*));
    NSInteger segments = self.segmentedUnits;
    for (NSInteger i = 0; i < countChannels; i++)
        self.computedData[i] = calloc(segments, sizeof(float));;
    
    self.isLoaded = YES;
}
-(NSMutableArray *)lastTypes{
    if(_lastTypes){
        _lastTypes = @[].mutableCopy;
        for (NSInteger i = 0; i < self.channels.count; i++)
             [_lastTypes addObject:@0];
    }
    return _lastTypes;
}
-(NSMutableArray *)lastOptions{
    if(_lastOptions){
        _lastOptions = @[].mutableCopy;
        for (NSInteger i = 0; i < self.channels.count; i++)
            [_lastOptions addObject:@0];
    }
    return _lastOptions;
}
#pragma mark save

-(void)saveData{
    
    NSMutableData *data = [NSMutableData data];
    NSInteger count = self.channels.count;
    for (NSInteger i = 0; i < count; i++){
        if(self.computedData[i])
            [data appendBytes:self.computedData[i] length:self.segmentedUnits * sizeof(float)];
    }
    
        
    NSError *error = nil;
    [data writeToFile:self.absolutePath options:NSDataWritingAtomic error:&error];
    if(error)
        NSLog(@"Write returned error: %@", [error localizedDescription]);
}

#pragma mark open

-(BOOL)hasBackData{
    return [[NSFileManager defaultManager]fileExistsAtPath:self.absolutePath];
}

-(void)open{
    /*if([self hasBackData]){
        [self prepData];
        NSData *data = [NSData dataWithContentsOfFile:path];
                
        float value;
        size_t floatSize = sizeof(float);
        NSInteger counter = 0;

        NSInteger channelsCount = self.channels.count;
        NSInteger units = self.segmentedUnits;
        
        for (NSInteger i = 0; i < channelsCount; i++) {

            for (NSInteger j = 0; j < units; j++) {
//                if(counter + floatSize > data.length)
//                    continue;
                [data getBytes:&value range:NSMakeRange(counter, floatSize)];
                self.computedData[i][j] = value;
                counter += floatSize;
            }
        }
    }*/

    if([self hasBackData]){
        
        NSData *data = [NSData dataWithContentsOfFile:self.absolutePath];

        NSInteger channelsCount = self.channels.count;
        NSInteger units = self.segmentedUnits;
        
        if(data.length < channelsCount * units * sizeof(float)){
            self.isLoaded = NO;
            dispatch_async(dispatch_get_main_queue(), ^{[General runAlertModalWithMessage:@"File corrupted"];});
            return;
        }
        
        [self prepData];
        NSInteger counter = 0;
        float *allBytes = (float *)data.bytes;
        for (NSInteger i = 0; i < channelsCount; i++) {
            for (NSInteger j = 0; j < units; j++) {
                self.computedData[i][j] = allBytes[counter];
                counter ++;
            }
        }
    }
}

#pragma mark my code for extraction

-(float)sumForArray:(float *)carray{
    if(!carray)
        return .0f;
    NSInteger counter = (NSInteger)(carray[0] - 1);
    float sum = .0f;
    for (NSInteger i = 0; i < counter; i++)
        sum += carray[i + 1];
    return sum;
}
-(float)medianForArray:(float *)carray{
    if(!carray)
        return .0f;
    NSInteger counter = (NSInteger)(carray[0] - 1);
    float *values = &carray[1];
    qsort (values, counter, sizeof(float), compare);
    return values[counter/2];
}
-(float)standardDeviationForArray:(float *)carray withMean:(float)mean recalcMean:(BOOL)recalc{
    if(!carray)
        return .0f;
    NSInteger counter = (NSInteger)(carray[0] - 1);
    float *values = &carray[1];
    
    if(recalc)
        mean = [self sumForArray:carray]/counter;
    
    double sumOfDifferencesFromMean = 0;
    for (NSInteger i = 0; i < counter; i++){
        //This is faster
        float val = values[i] - mean;
        sumOfDifferencesFromMean += (val * val);
        //Than this
        //sumOfDifferencesFromMean += pow((values[i] - mean), 2);
        //http://stackoverflow.com/questions/2940367/what-is-more-efficient-using-pow-to-square-or-just-multiply-it-with-itself
    }
    
    return sqrt(sumOfDifferencesFromMean / counter);
}

//Tie computations
-(NSInteger)channelsCreate:(NSIndexSet *)computations{
    NSArray *chans = self.mask.imageStack.channels;
    NSInteger countComps = [computations countOfIndexesInRange:NSMakeRange(0, 4)];
    
    countComps = [computations countOfIndexesInRange:NSMakeRange(4, 16)];
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:chans.count + 2];
    
    [arr addObject:@"CellId"]; countComps++;
    
    
    NSArray *strs1 = @[@"cell_",@"nuc_",@"cyt_", @"ratio_cyt_to_nuc_"];
    NSArray *strs2 = @[@"tot_",@"avg_",@"med_",@"std_"];
    
    for (NSString *str in chans) {
        for(int i = 0; i < 4; i++)
            if([computations containsIndex:i])
                [arr addObject:[strs1[0] stringByAppendingString:[strs2[i] stringByAppendingString:str]]];
        
        for(int i = 4; i < 16; i++)
            if([computations containsIndex:i])
                [arr addObject:[[strs1[i/4] stringByAppendingString:strs2[i % 4]]stringByAppendingString:str]];
        
    }
    
    [arr addObject:@"size_ratio_cyt_to_nuc"];
    [arr addObject:@"Size_nuc"];
    [arr addObject:@"Size_cyt"];
    countComps += 3;
    

    //Indexes for X and Y
    [arr addObject:@"Size"];
    [arr addObject:@"X"];
    [arr addObject:@"Y"];
    [arr addObject:@"Density"];
    countComps += 4;
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS] = arr;
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS] = arr.mutableCopy;
    
    return countComps;
}

-(void)extractDataForMaskOperation:(NSIndexSet *)computations processedData:(BOOL)rawOrProcessedData{
    [self channelsCreate:computations];
    //Get the mask
    int * maskC = [self.mask mask];
    
    //Get the IMC data
    float ** allData = self.mask.imageStack.stackData;
    
    if(rawOrProcessedData){
        NSLog(@"Add data________");
        NSMutableArray *allIndexes = @[].mutableCopy;
        for (NSInteger i = 0; i < self.mask.imageStack.channels.count; i++)
            [allIndexes addObject:@(i)];
        UInt8 ** adjustedData = [self.mask.imageStack preparePassBuffers:allIndexes];
        allData = (float **)malloc(self.mask.imageStack.channels.count * sizeof(float *));
        NSInteger numberOfPixels = self.mask.imageStack.numberOfPixels;
        for (NSInteger i = 0; i < self.mask.imageStack.channels.count; i++) {
            allData[i] = malloc(numberOfPixels * sizeof(float));
            for (NSInteger j = 0; j < numberOfPixels; j++)
                allData[i][j] = (float)adjustedData[i][j];
        }
    }
    
    NSArray *imcChannels = self.mask.imageStack.channels;
    
    NSInteger rawChannels = imcChannels.count;
    NSInteger computedChannels = self.channels.count;
    
    NSInteger sizePicture = self.mask.imageStack.numberOfPixels;
    NSInteger width = self.mask.imageStack.width;
    NSInteger height = self.mask.imageStack.height;
    
    [self prepData];
    float ** comp = self.computedData;
    int * copyOfMask = copyMask(maskC, (int)width, (int)height);
    
    //Prep DS
    //Prep array
    
    NSInteger compartmentsExtractedFromChannels = rawChannels * 3;
    float ** arr = calloc(compartmentsExtractedFromChannels, sizeof(float *));
    for (int a = 0; a < compartmentsExtractedFromChannels; a++){
        arr[a] = calloc(sizePicture + 1, sizeof(float));
    }

    for (NSInteger i = 0; i < sizePicture; i++) {
        NSInteger theId = abs(copyOfMask[i]);
        NSInteger index = theId - 1;
        if(theId != 0 && comp[0][index] == 0){
            //Get pixels for every object and sum of X and Y
            comp[computedChannels - 3][index] += (float)((i + width)%width);
            comp[computedChannels - 2][index] += (float)(i/width);
            
            copyOfMask[i] = 0;
            NSMutableArray *pixels = @[].mutableCopy;
            NSMutableArray *collected = @[].mutableCopy;
            NSNumber *anal = @(i);
            while (anal) {
                NSInteger analI = anal.integerValue;
                for (int l = -1; l < 2; l++) {
                    for (int m = -1; m < 2; m++) {
                        NSInteger test = analI + l * width + m;
                        if(test >= 0 && test < sizePicture)
                            if(abs(copyOfMask[test]) == theId){
                                [pixels addObject:@(test)];
                                copyOfMask[test] = 0;
                            }
                    }
                }
                [collected addObject:anal];
                anal = pixels.lastObject;
                [pixels removeLastObject];
            }
            //ID
            comp[0][index] = theId;
            //Size
            comp[computedChannels - 4][index] = collected.count;
            //Features
            for (int a = 0; a < compartmentsExtractedFromChannels; a++) {
                arr[a][0] = 1;
            }
            ////Prep data
            for (NSNumber *idx in collected) {
                NSInteger idxC = idx.integerValue;
                BOOL isNuc = (maskC[idxC] < 0);
                //comp[computedChannels - 4][index]++;
                if(!isNuc)
                    comp[computedChannels - 5][index]++;
                else
                    comp[computedChannels - 6][index]++;
                
                for (int a = 0; a < rawChannels; a++) {
                    float val = allData[a][idxC];
                    int baseIndex = a * 3;
                    arr[baseIndex][(int)arr[baseIndex][0]] = val;
                    arr[baseIndex][0]++;
                    baseIndex++;
                    if(isNuc){
                        arr[baseIndex][(int)arr[baseIndex][0]] = val;
                        arr[baseIndex][0]++;
                    }else{
                        baseIndex++;
                        arr[baseIndex][(int)arr[baseIndex][0]] = val;
                        arr[baseIndex][0]++;
                    }
                }
            }
            ////Start Adding
            for (int a = 0; a < rawChannels; a++) {
                int counter = 0;
                NSInteger baseIndex = a * computations.count + 1;
                for (int idx = 0; idx < 16; idx++) {
                    if([computations containsIndex:idx]){
                        NSInteger basePlusCounter = baseIndex + counter;
                        float * arrr = NULL;
                        if(idx < 4)
                            arrr = arr[a * 3];
                        else if(idx < 8)
                            arrr = arr[a * 3 + 1];
                        else if(idx < 12)
                            arrr = arr[a * 3 + 2];
                        
                        int compon = idx % 4;
                        if(idx < 12 && arrr){
                            float sum = [self sumForArray:arrr];
                            
                            if(compon == 0)
                                comp[basePlusCounter][index] = sum;
                            
                            if(compon == 1)
                                comp[basePlusCounter][index] = arrr[0] > 1 ? sum/(arrr[0]-1) : .0f;

                            if(compon == 2)
                                comp[basePlusCounter][index] = [self medianForArray:arrr];

                            if(compon == 3)
                                comp[basePlusCounter][index] = arrr[0] > 1 ? [self standardDeviationForArray:arrr withMean:sum/(arrr[0] - 1) recalcMean:NO] : 0;
                        }
                        if(idx >= 12 && !arrr){
                            float *first = arr[a * 3 + 1];
                            float *second = arr[a * 3 + 2];
                            float sumF = [self sumForArray:first];
                            float sumS = [self sumForArray:second];
                            if(sumS > 0){
                                if(compon == 0)
                                    comp[basePlusCounter][index] = sumF/sumS;
                                
                                if(compon == 1)
                                    comp[basePlusCounter][index] = first[0] > 1 && second[0] > 1 ? (sumF/(first[0] - 1))/(sumS/(second[0] - 1)) : .0f;
                                
                                if(compon == 2){
                                    float medB = [self medianForArray:second];
                                    comp[basePlusCounter][index] = medB > 0 ? [self medianForArray:first]/medB : 0;
                                }
                                if(compon == 3){
                                    float stdB = [self standardDeviationForArray:second withMean:sumS/(first[0] - 1) recalcMean:NO];
                                    comp[basePlusCounter][index] = stdB > 0 ? [self standardDeviationForArray:first withMean:sumF/(first[0] - 1) recalcMean:NO]/stdB : 0;
                                }
                            }
                        }
                        
                        counter++;
                    }
                }
            }
        }
    }
    
    NSInteger segments = self.segmentedUnits;
    //Neighbours
    int * neighbours = [self calculateNeighboursTouchingForMask:maskC width:width height:height];
    for (NSInteger i = 0; i < segments; i++)
        comp[computedChannels - 1][i] = neighbours[i];
    
    [self saveData];
    
    free(neighbours);
    for (int a = 0; a < compartmentsExtractedFromChannels; a++){
        free(arr[a]);
    }
    free(arr);
    
    if(rawOrProcessedData){
        for (NSInteger i = 0; i < self.mask.imageStack.channels.count; i++)
            free(allData[i]);
        free(allData);
    }
    NSLog(@"Finished extracting");
}


-(void)extractDataForMask:(NSIndexSet *)computations processedData:(BOOL)rawOrProcessedData{
    [self.mask.imageStack openIfNecessaryAndPerformBlock:^{
        [self extractDataForMaskOperation:computations processedData:rawOrProcessedData];
    }];
}


-(int *)calculateNeighboursTouchingForMask:(int *)mask width:(NSInteger)width height:(NSInteger)height{
    NSInteger max = [self.mask numberOfSegments];
    
    int * bordersMask = copyMask(mask, (int)width, (int)height);
    bordersOnlyMask(bordersMask, width, height);
    NSInteger total = width * height;
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:max];
    NSInteger size = width * height;
    for (NSInteger i = 0; i < size; i++) {
        int cellId = bordersMask[i];
        if (cellId == 0)continue;
        bordersMask[i] = 0;
        for (int x = -1; x < 2; x++) {
            for (int y = -1; y < 2; y++) {
                if(x == 0 && y == 0)continue;
                NSInteger testIndex = i + y * width + x;
                if(doesNotJumpLine(i, testIndex, width, height, total, 3) == YES){
                    int test = mask[testIndex];
                    if (test != 0 && test != cellId){
                        NSMutableArray *neigs = [dic valueForKey:[NSString stringWithFormat:@"%i", cellId]];
                        if(!neigs)neigs = [NSMutableArray array];
                        NSNumber *num = @(test);
                        if(![neigs containsObject:num]){
                            [neigs addObject:num];
                        }
                        [dic setValue:neigs forKey:[NSString stringWithFormat:@"%i", cellId]];
                    }
                }
            }
        }
    }
    int * neighbours = calloc(max, sizeof(int));
    for (NSInteger i = 0; i < max; i++) {
        neighbours[i] = (int)[[dic valueForKey:[NSString stringWithFormat:@"%li", i + 1]]count];
    }
    free(bordersMask);
    return neighbours;
}

#pragma mark use extraction from Cell Profiler

-(void)addFeaturesFromCellProfiler:(NSURL *)url{
    
    NSString *str = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    NSArray *lines = [str componentsSeparatedByString:@"\n"];
    if(lines.count < 2)return;
    
    NSArray *headers = [lines.firstObject componentsSeparatedByString:@"\t"];
    NSInteger channelsCount = self.channels.count;
    
    NSLog(@"%@", self.channels);
    
    NSInteger allCount = channelsCount + headers.count;
    
    float ** newData = (float **)calloc(allCount, sizeof(float*));
    for (NSInteger i = 0; i < allCount; i++) {
        newData[i] = calloc(self.segmentedUnits, sizeof(float));
    }
    
    int counterLine = 1;
    
    NSMutableArray *channels = [self channels];
    for (NSInteger i = 0; i < self.segmentedUnits; i++) {
        //First add the other data
        for (int j = 0; j < channels.count; j++) {
            newData[j][i] = self.computedData[j][i];
        }
        
        BOOL valid = NO;
        
        NSString *line;
        NSArray *values;
        do {
            line = [lines objectAtIndex:counterLine];
            values = [line componentsSeparatedByString:@"\t"];
            if(values.count < 3)return;
            if([values[2]integerValue] > 0)valid = YES;
            counterLine++;
        } while (valid == NO);
        if(!values)continue;
        
        for (int j = 0; j < headers.count; j++) {
            newData[j + channelsCount][i] = [values[j]floatValue] * 1000;
        }
    }
    [self release_computedData];
    self.computedData = newData;
    [self.channels addObjectsFromArray:headers];
    
    [self saveData];
}

#pragma mark Image Generation for mask

-(UInt8 *)getCachedBufferForIndex:(NSInteger)index maskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    if(cachedValues == NULL || cachedSettings == NULL)
        [self allocateCacheBufferContainers];
    if(cachedValues[index] == NULL || cachedSettings[index] == NULL)
        [self allocateCacheBuffersForIndex:index withPixels:self.mask.imageStack.numberOfPixels];
    if([self compareCachedSettingsWithCurrentForIndex:index] == YES
                    || option != [self.lastOptions[index]integerValue]
                    || maskType != [self.lastTypes[index]integerValue]){
        [self recalculateChannelAtIndex:index maskOption:option maskType:maskType maskSingleColor:maskSingleColor];
    }
    [self.lastOptions replaceObjectAtIndex:index withObject:[NSNumber numberWithInteger:option]];
    [self.lastTypes replaceObjectAtIndex:index withObject:[NSNumber numberWithInteger:maskType]];
    return cachedValues[index];
}

-(BOOL)compareCachedSettingsWithCurrentForIndex:(NSInteger)index{//Compares and prepares the buffer
    if(index >= self.channels.count)return YES;
    float * settings = cachedSettings[index];
    NSMutableDictionary *setts = [self channelSettings][index];
    
    BOOL foundDiff = NO;
    NSArray *keys = @[JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET, JSON_DICT_CHANNEL_SETTINGS_OFFSET, JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER,JSON_DICT_CHANNEL_SETTINGS_SPF, JSON_DICT_CHANNEL_SETTINGS_TRANSFORM];
    
    for (int i = 0; i < 5; i++) {
        if(settings[i] != [setts[keys[i]]floatValue]){
            foundDiff = YES;
            settings[i] = [setts[keys[i]]floatValue];
        }
        
    }
    return foundDiff;
}

-(float)maxInBuffer:(float *)buffer{
    if(!buffer)return 1.f;
    float max = .0f;
    NSInteger pixs = self.segmentedUnits;
    for (NSInteger i = 0; i < pixs; i++) {
        if(buffer[i] > max)max = buffer[i];
    }
    return max;
}

-(float)maxForIndex:(NSInteger)index{
    if(cachedSettings)
        if (cachedSettings[index])
            return cachedSettings[index][5];
    if(self.computedData)
        if(self.computedData[index])
            return [self maxInBuffer:self.computedData[index]];
    return 255.0f;
}

-(void)recalculateChannelAtIndex:(NSInteger)index maskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    float * settings = cachedSettings[index];
    if(!self.computedData)
        return;
    if(!self.computedData[index])
        return;
    
    if(!cachedValues)
        [self allocateCacheBufferContainers];
    
    float *vals = [self createImageForMaskWithCellData:self.computedData[index] maskOption:option maskType:maskType maskSingleColor:maskSingleColor];
    
    if(!vals || !settings)return;
    
    if(settings[5] == .0f)
        settings[5] = [self maxInBuffer:self.computedData[index]];
    
    NSInteger pixs = self.mask.imageStack.numberOfPixels;
    
    float preCalcFactor = (float)(settings[5] * settings[0]);
    for (NSInteger i = 0; i < pixs; i++) {
        float val = vals[i];
        if(settings[4] == 1.0f)val = logf(val);
        if(settings[4] == 2.0f)val = asinhf(val/5.0f);
        UInt8 bitValue = MIN(255, (val/preCalcFactor * 255)*settings[2]);
        if(bitValue < settings[1] * 255)bitValue = 0;
        cachedValues[index][i] = bitValue;
    }
    if(settings[3] > 0)
        applyFilterToPixelData(cachedValues[index], self.mask.imageStack.width, self.mask.imageStack.height, 0, settings[3], 2, 1);
    
    if(vals)
        free(vals);
}

-(void)allocateCacheBuffersForIndex:(NSUInteger)index withPixels:(NSUInteger)pixels{
    if(!cachedValues)
        return;
    if(cachedValues[index] != NULL)
        free(cachedValues[index]);
    cachedValues[index] = NULL;
    if(cachedValues[index] == NULL)
        cachedValues[index] = (UInt8 *)calloc(self.mask.imageStack.numberOfPixels, sizeof(UInt8));
    
    
    if(cachedSettings[index] == NULL){
        cachedSettings[index] = (float *)calloc(6, sizeof(float));
        cachedSettings[index][0] = .0f;
        cachedSettings[index][1] = .0f;
        cachedSettings[index][2] = .0f;
        cachedSettings[index][3] = .0f;
        cachedSettings[index][4] = .0f;
        cachedSettings[index][5] = .0f;
    }
}

-(void)allocateCacheBufferContainers{
    if(cachedValues != NULL)free(cachedValues);
    cachedValues = NULL;
    if(cachedValues == NULL){
        cachedValues = (UInt8 **)calloc(self.channels.count, sizeof(UInt8 *));
    }
    
    if(cachedSettings != NULL)free(cachedSettings);
    cachedSettings = NULL;
    if(cachedSettings == NULL){
        cachedSettings = (float **)calloc(self.channels.count, sizeof(float *));
    }
}
-(NSString *)absolutePath{
    return [[self.fileWrapper.workingFolder stringByAppendingPathComponent:self.mask.itemHash]stringByAppendingPathExtension:@"cbin"];
}
-(float *)createImageForMaskWithCellData:(float *)data maskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    
    int * copy = copyMask(self.mask.mask, (int)self.mask.imageStack.width, (int)self.mask.imageStack.height);
    
    float * img = calloc(self.mask.imageStack.numberOfPixels, sizeof(float));
    if(data == NULL)return NULL;
    
    NSInteger pix = self.mask.imageStack.numberOfPixels;
    for (NSInteger i = 0; i < pix; i++) {
        if(copy[i] == 0)continue;
        NSInteger index = abs(copy[i]) - 1;
        
        if(maskType == MASK_ALL_CELL){
            img[i] = data[index];
            copy[i] = abs(copy[i]);
        }
        
        else if(maskType == MASK_CYT){
            img[i] = MAX((copy[i] > 0) * data[index], 0);
            copy[i] = copy[i] > 0?copy[i]:0;
        }
        
        else if(maskType == MASK_NUC){
            img[i] = MAX((copy[i] < 0) * data[index], 0);
            copy[i] = copy[i] < 0?-copy[i]:0;
        }
        else if(maskType == MASK_NUC_PLUS_CYT){
            img[i] = (copy[i]/abs(copy[i])) * data[index];
        }
        
    }
    if(option == 0 || option == 3)
        bordersOnlyMask(copy, self.mask.imageStack.width, self.mask.imageStack.height);
    if(option == 2)
        noBordersMask(copy, self.mask.imageStack.width, self.mask.imageStack.height);
    for (NSInteger i = 0; i < pix; i++)
        if(copy[i] == 0)
            img[i] = 0;
    
    free(copy);
    return img;
}

-(CGImageRef)coloredMaskForChannel:(NSInteger)channel color:(NSColor *)color maskOption:(MaskOption)option maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor brightField:(BOOL)brightField{
    if(channel == NSNotFound)
        return NULL;
    UInt8 * ints = [self getCachedBufferForIndex:channel maskOption:option maskType:maskType maskSingleColor:maskSingleColor];

    CGImageRef ref = [IMCImageGenerator imageFromCArrayOfValues:ints color:color width:self.mask.imageStack.width height:self.mask.imageStack.height startingHueScale:170 hueAmplitude:170 direction:NO ecuatorial:NO brightField:brightField];
    return ref;
}


#pragma mark Calculations

-(NSMutableArray *)arrayNumbersForIndex:(NSInteger)index{
    NSMutableArray *array = @[].mutableCopy;
    NSInteger cells = self.mask.numberOfSegments;
    float *data = self.computedData[index];
    for (int i = 0; i < cells; i++) {
        float val = data[i];
        if(val > 0){
            [array addObject:[NSNumber numberWithFloat:val]];
        }
    }
    return array;
}
-(NSArray *)arrayOfChannelArrays:(NSIndexSet *)indexSet{
    NSMutableArray *array = @[].mutableCopy;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        [array addObject:[self arrayNumbersForIndex:index]];
    }];
    return array;
}
-(NSDictionary *)statsForIndex:(NSInteger)index{
    
    if(!self.statsComputed){
        self.statsComputed = @{}.mutableCopy;
    }
    if(!self.computedData)
        return nil;
    
    if(!self.computedData[index])
        return nil;
    
    if(index < 0 || index >= self.channels.count)
        return nil;
    
    
    NSMutableDictionary *dic = [self.statsComputed valueForKey:[NSString stringWithFormat:@"%li", index]];
    if(!dic){
        dic = @{}.mutableCopy;
        
        NSMutableArray *array = [self arrayNumbersForIndex:index];
        
        dic[@"count"] = @(array.count);
        if(array.count > 0){
            dic[@"avg"] = [array mean];
            dic[@"med"] = [array median];
            dic[@"std"] = [array standardDeviation];
            dic[@"total"] = [array sum];
        }
    }
    return [NSDictionary dictionaryWithDictionary:dic];
}
-(NSArray *)statsForIndexSet:(NSIndexSet *)indexSet{
    NSMutableArray *indexes = @[].mutableCopy;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger ind, BOOL *stop){
        id obj = [self statsForIndex:ind];
        if(obj)
            [indexes addObject:obj];
    }];
    return [NSArray arrayWithArray:indexes];
}
-(NSArray *)countStatsForStack:(NSIndexSet *)indexSet{
    NSArray *channelsStack = [self statsForIndexSet:indexSet];
    NSMutableArray *singles = @[].mutableCopy;
    for (NSDictionary *chanDic in channelsStack) {
        [singles addObject:[NSNumber numberWithInt:[chanDic[@"count"]intValue]]];
    }
    
    return [NSArray arrayWithArray:singles];
}

-(NSString *)countForChannelArray:(NSArray *)array{return [NSString stringWithFormat:@"%li", array.count];}
-(NSString *)meanForChannelArray:(NSArray *)array{return [NSString stringWithFormat:@"%f", [array mean].floatValue];}
-(NSString *)modeForChannelArray:(NSArray *)array{return [NSString stringWithFormat:@"%f", [array median].floatValue];}
-(NSString *)stddForChannelArray:(NSArray *)array{return [NSString stringWithFormat:@"%f", [array standardDeviation].floatValue];}
-(NSString *)totalForChannelArray:(NSArray *)array{return [NSString stringWithFormat:@"%f", [array sum].floatValue];}


-(float)averagedSumOfSquaresForArray:(NSArray *)arrayOfChannelArrays{
    
    float sum = .0f;
    if(self.segmentedUnits > 0){
        for (NSArray *arr in arrayOfChannelArrays)
            sum += [arr sumOfSquares];
        sum /= self.segmentedUnits;
    }
    return sum;
}
-(NSString *)shannonForCountStatsArray:(NSArray *)countStatsArray{return [NSString stringWithFormat:@"%f", countStatsArray.shannonIndex];}
-(NSString *)simpsonForCountStatsArray:(NSArray *)countStatsArray{return [NSString stringWithFormat:@"%f", countStatsArray.simpsonIndex];}



-(NSString *)formatStats:(NSDictionary *)stats{
    NSMutableString *str = @"".mutableCopy;
    for (NSString *key in stats.allKeys) {
        [str appendString:key];
        [str appendString:@": "];
        [str appendFormat:@"%.4f", [stats[key]floatValue]];
        [str appendString:@"\n"];
    }
    return str.copy;
}
-(int)xIndexInArray:(NSArray *)array{
    int xIndex = -1;
    for (NSString *str in array) {
        if ([str isEqualToString:@"X"] || [str isEqualToString:@"avg_X"])xIndex = (int)[self.channels indexOfObject:str];
    }
    return xIndex;
}

-(int)yIndexInArray:(NSArray *)array{
    int yIndex = -1;
    for (NSString *str in array) {
        if ([str isEqualToString:@"Y"] || [str isEqualToString:@"avg_Y"])yIndex = (int)[self.channels indexOfObject:str];
    }
    return yIndex;
}
-(NSArray *)centroidsForChannel:(NSInteger)channel{
    int xIndex = [self xIndexInArray:self.channels];
    int yIndex = [self yIndexInArray:self.channels];
    NSMutableArray *collected = @[].mutableCopy;
    NSInteger cells = self.mask.numberOfSegments;
    for (int i = 0; i < cells; i++) {
        float selector = self.computedData[channel][i];
        if(selector > 0){
            CGPoint point = CGPointMake(self.computedData[xIndex][i], self.computedData[yIndex][i]);
            [collected addObject:[NSValue valueWithPoint:point]];
        }
    }
    return [NSArray arrayWithArray:collected];
}
-(float *)xCentroids{
    int xIndex = [self xIndexInArray:self.channels];
    return self.computedData[xIndex];
}
-(float *)yCentroids{
    int yIndex = [self yIndexInArray:self.channels];
    return self.computedData[yIndex];
}
-(NSString *)descriptionWithIndexes:(NSIndexSet *)indexSet{
    NSMutableString *str = @"".mutableCopy;
    if(indexSet.count == 1)
        [str appendString:[self formatStats:[self statsForIndex:indexSet.firstIndex]]];
    if(indexSet.count == 2){
        NSMutableArray *array = @[].mutableCopy;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [array addObject:[self centroidsForChannel:idx]];
        }];
        
        float ward = [IMCUtils wardForArray1:array.firstObject array2:array.lastObject];
        float mIV = [IMCUtils minimalIncreaseOfVarianceForArray1:array.firstObject array2:array.lastObject];
        float sumSqAll = [IMCUtils sumOfSquareDistancesPointArray:array.firstObject] + [IMCUtils sumOfSquareDistancesPointArray:array.lastObject];
        //        float a = [IMCUtils nomeacuerdolocambiare:array.firstObject array2:array.lastObject];
        //        float b = [IMCUtils nomeacuerdolocambiareWeighter:array.firstObject array2:array.lastObject];
        if(!VIEWER_ONLY && !VIEWER_HISTO)
            [str appendString:[NSString stringWithFormat:@"Ward: %f\nMIV: %f\nSumSq %f\n", ward, mIV, sumSqAll]];
        
    }
    if(indexSet.count > 1){
        NSArray *arr = [self countStatsForStack:indexSet];
        
        [str appendString:[NSString stringWithFormat:@"Counts: %li\nShanon: %f\nSimpson: %f",
                                             [[arr sum]integerValue],
                                             [arr shannonIndex],
                                             [arr simpsonIndex]
                                             ]];
        
    }
    return str.copy;
}

#pragma mark add results
-(void)addBuffer:(float *)buffer withName:(NSString *)name atIndex:(NSInteger)index{
    
    [self clearCacheBuffers];
    
    if(index == NSNotFound || index > self.channels.count)
        index = self.channels.count;
    
    if(!self.isLoaded)
        [self loadLayerDataWithBlock:nil];
    while (!self.isLoaded);
    
    NSInteger oldNumberOfChannels = self.channels.count;
    
    float ** old = calloc(oldNumberOfChannels, sizeof(float *));
    for(NSInteger i = 0; i < oldNumberOfChannels; i++)
        old[i] = self.computedData[i];
    
    NSUInteger alreadyInComp = [self.channels indexOfObject:name];
    
    if(alreadyInComp != NSNotFound){
        if(self.computedData[alreadyInComp])
            free(self.computedData[alreadyInComp]);
        self.computedData[alreadyInComp] = buffer;
    }else{
        [self.channels insertObject:name atIndex:index];
        
        if(self.computedData)
            free(self.computedData);
        
        self.computedData = calloc(self.channels.count, sizeof(float *));
        
        for(NSInteger i = 0; i < oldNumberOfChannels + 1; i++){
            if(i == index)
                self.computedData[i] = buffer;
            else
                self.computedData[i] = old[i - (i > index)];
        }
    }
    
    [self saveData];
    free(old);
}
#pragma mark other operations on channels

-(void)removeChannelsWithIndexSet:(NSIndexSet *)indexSet{
    
    if(self.computedData && self.isLoaded){
        
        NSInteger oldCount = self.channels.count;
        [self.originalChannels removeObjectsAtIndexes:indexSet];
        [self.channels removeObjectsAtIndexes:indexSet];
        
        float ** new = calloc(oldCount - indexSet.count, sizeof(float *));
        NSInteger counter = 0;
        for (NSInteger i = 0; i < oldCount; i++) {
            if([indexSet containsIndex:i]){
                if(self.computedData[i]){
                    free(self.computedData[i]);
                    self.computedData[i] = NULL;
                }
            }else{
                new[counter] = self.computedData[i];
                counter++;
            }
        }
        
        free(self.computedData);
        self.computedData = new;
        [self clearCacheBuffers];
        [self saveData];
    }
}
-(void)addChannelsWithIndexSet:(NSIndexSet *)indexSet toInlineIndex:(NSInteger)index{
    if(self.computedData && self.isLoaded){
        
        NSMutableString *str = @"".mutableCopy;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [str appendString:self.channels[idx]];
            if(idx != indexSet.lastIndex)
                [str appendString:@"+"];
        }];
        
        NSInteger cells = self.mask.numberOfSegments;
        float * newChan = calloc(cells, sizeof(float));
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            for (NSInteger i = 0; i < cells; i++)
                newChan[i] += self.computedData[idx][i];
        }];
        
        [self addBuffer:newChan withName:[NSString stringWithFormat:@"SUM(%@)", str] atIndex:index];
    }
}
-(void)multiplyChannelsWithIndexSet:(NSIndexSet *)indexSet toInlineIndex:(NSInteger)index{
    if(self.computedData && self.isLoaded){
        
        NSMutableString *str = @"".mutableCopy;
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [str appendString:self.channels[idx]];
            if(idx != indexSet.lastIndex)
                [str appendString:@"+"];
        }];
        
        NSInteger cells = self.mask.numberOfSegments;
        float * newChan = calloc(cells, sizeof(float));
        for (NSInteger i = 0; i < cells; i++)
            newChan[i] = 1;//init all to one because is multiplication
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            for (NSInteger i = 0; i < cells; i++)
                newChan[i] *= self.computedData[idx][i];
        }];
        
        [self addBuffer:newChan withName:[NSString stringWithFormat:@"PROD(%@)", str] atIndex:index];
    }
}

#pragma mark prep data various samples

+(BOOL)flockForComps:(NSArray<IMCComputationOnMask *> *)comps indexes:(NSIndexSet *)indexSet{
    BOOL success = YES;
    
    //Perform checks
    if(comps.count == 0){
        [General runAlertModalWithMessage:@"You must select at least one mask computation (cell data)"];
        success = NO;
    }
    if(indexSet.count == 0){
        [General runAlertModalWithMessage:@"You must select at least one channel"];
        success = NO;
    }
    
    NSInteger channels = comps.firstObject.channels.count;
    for (IMCComputationOnMask *comp in comps)
        if(comp.channels.count != channels)
            success = NO;
    if(!success)
        [General runAlertModalWithMessage:@"All cell data files must have the same number of channels"];
    if(indexSet.lastIndex >= comps.firstObject.channels.count)
        success = NO;
    
    if(success){
        NSInteger allCells = 0;
        NSMutableArray *closeAtEnd = @[].mutableCopy;
        for(IMCComputationOnMask *comp in comps){
            BOOL wasLoaded = comp.isLoaded;
            if(!wasLoaded)
                [comp loadLayerDataWithBlock:nil];
            while(!comp.isLoaded);
            if(!wasLoaded)
                [closeAtEnd addObject:comp];
            allCells += comp.segmentedUnits;
        }
        int *clusters = (int *) calloc(allCells, sizeof(int));//not iVar anymore
        
        NSInteger channsToAnalyze = indexSet.count;
        double ** data = (double **)malloc(allCells * sizeof(double *));
        for (int i = 0; i < allCells; i++)
            data[i] = malloc(channsToAnalyze * sizeof(double));
        
        NSInteger offSetCells = 0;
        for (IMCComputationOnMask *comp in comps) {
            __block int counter = 0;
            NSInteger cellsComp = comp.segmentedUnits;
            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
                for (int i = 0; i < cellsComp; i++)
                    data[offSetCells + i][counter] = asinh(comp.computedData[idx][i]);
                counter++;
            }];
            offSetCells += cellsComp;
        }
        directMethod(indexSet.count, allCells, data, clusters);
        
        NSUInteger highest = 0;
        for (int i =0 ; i < allCells; i++) {
            if(clusters[i] > highest)
                highest = clusters[i];
        }
        
        offSetCells = 0;
        NSString *stamp = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
        NSString *opName = [@"Flock_" stringByAppendingString:stamp];
        
        for (IMCComputationOnMask *comp in comps) {
            NSInteger cellsComp = comp.segmentedUnits;
            float * result = malloc(cellsComp * sizeof(float));
            for (int i = 0; i < cellsComp; i++)
                result[i] = (float)clusters[offSetCells + i];
            [comp addBuffer:result withName:opName atIndex:NSNotFound];
            for (int j = 0; j < highest; j++) {
                float * itemized = malloc(cellsComp * sizeof(float));
                for (int i = 0; i < cellsComp; i++)
                    itemized[i] = clusters[offSetCells + i] == j ? 1.0f : 0.0f;
                [comp addBuffer:itemized withName:[NSString stringWithFormat:@"Cluster_%i_%@", j, opName] atIndex:NSNotFound];
            }
            offSetCells += cellsComp;
        }
        free(clusters);
        
        for (IMCComputationOnMask *comp in closeAtEnd)
            [comp unLoadLayerDataWithBlock:nil];
    }
    
    return success;
}

#pragma mark memmory management

-(void)release_computedData{
    if(self.computedData){
        for (NSInteger i = 0; i < self.channels.count; i++)
            if(self.computedData[i]){
                free(self.computedData[i]);
                self.computedData[i] = NULL;
            }
        
        free(self.computedData);
        self.computedData = NULL;
    }
}

-(void)clearCacheBuffers{
    if(cachedValues != NULL){
        for (int i = 0; i < self.channels.count; i++)
            if(cachedValues[i] != NULL){
                free(cachedValues[i]);
                cachedValues[i] = NULL;
            }
        free(cachedValues);
        cachedValues = NULL;
    }
    if(cachedSettings != NULL){
        for (int i = 0; i < self.channels.count; i++)
            if(cachedSettings[i] != NULL){
                free(cachedSettings[i]);
                cachedSettings[i] = NULL;
            }
        
        free(cachedSettings);
        cachedSettings = NULL;
    }
}
-(NSUInteger)usedMegaBytes{
    
    NSUInteger bytes = 0;
    if(cachedValues)
        for (NSInteger i = 0; i < self.channels.count; i++)
            if(cachedValues[i])
                bytes += self.mask.imageStack.numberOfPixels/pow(2, 20);
    if(self.computedData)
        bytes += self.mask.numberOfSegments * self.channels.count * sizeof(float)/pow(2, 20);
    
    return bytes;
}
-(void)dealloc{
    NSLog(@"_____DEALLOCING MASK COMPS");
    [self release_computedData];
    [self clearCacheBuffers];
}

@end
