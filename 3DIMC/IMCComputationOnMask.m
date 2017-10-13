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
    
    while(!self.mask.isLoaded);
    
    if(!self.isLoaded)
        [self open];
    
    while(!self.isLoaded);
    
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
    
    for (NSInteger i = 0; i < countChannels; i++)
        self.computedData[i] = malloc(self.segmentedUnits * sizeof(float));//Old solution
    
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
    NSString *path = [[self.fileWrapper.workingFolder stringByAppendingPathComponent:self.mask.itemHash]stringByAppendingPathExtension:@".cbin"];
    NSMutableData *data = [NSMutableData data];
    NSInteger count = self.channels.count;
    for (NSInteger i = 0; i < count; i++)
        if(self.computedData[i])
            [data appendBytes:self.computedData[i] length:self.segmentedUnits * sizeof(float)];
    
    
        
    NSError *error = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    if(error)
        NSLog(@"Write returned error: %@", [error localizedDescription]);
}

#pragma mark open

-(BOOL)hasBackData{
    NSString *path = [[self.workingFolder stringByAppendingPathComponent:self.mask.itemHash]stringByAppendingPathExtension:@".cbin"];
    return [[NSFileManager defaultManager]fileExistsAtPath:path];
}

-(void)open{
    
    NSString *path = [[self.workingFolder stringByAppendingPathComponent:self.mask.itemHash]stringByAppendingPathExtension:@".cbin"];
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
        [self prepData];
        NSData *data = [NSData dataWithContentsOfFile:path];
        float *allBytes = (float *)data.bytes;
        
        NSInteger counter = 0;
        
        NSInteger channelsCount = self.channels.count;
        NSInteger units = self.segmentedUnits;
        
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
    NSInteger counter = (NSInteger)(carray[0] - 1.0f);
    float sum = .0f;
    for (NSInteger i = 0; i < counter; i++)
        sum += carray[i + 1];
    return sum;
}
-(float)medianForArray:(float *)carray{
    if(!carray)
        return .0f;
    NSInteger counter = (NSInteger)(carray[0] - 1.0f);
    float *values = &carray[1];
    qsort (values, counter, sizeof(float), compare);
    return values[counter/2];
}
-(float)standardDeviationForArray:(float *)carray withMean:(float)mean recalcMean:(BOOL)recalc{
    if(!carray)
        return .0f;
    NSInteger counter = (NSInteger)(carray[0] - 1.0f);
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

//-(void)channelsCreateOld:(NSIndexSet *)computations{
//    NSArray *chans = self.mask.imageStack.channels;
//    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:chans.count + 2];
//    [arr addObject:@"CellId"];
//    
//    if([self.mask isDual] == NO)
//        for (NSString *str in chans) {
//            [arr addObject:[@"tot_" stringByAppendingString:str]];
//            [arr addObject:[@"avg_" stringByAppendingString:str]];
//            [arr addObject:[@"med_" stringByAppendingString:str]];
//            [arr addObject:[@"std_" stringByAppendingString:str]];
//        }
//    else{
//        NSArray *strs1 = @[@"cell_",@"nuc_",@"cyt_", @"ratio_cyt_to_nuc_"];
//        NSArray *strs2 = @[@"tot_",@"avg_",@"med_",@"std_"];
//        
//        for (NSString *str in chans) {
//            for (NSString *str1 in strs1) {
//                for (NSString *str2 in strs2) {
//                    [arr addObject:[[str1 stringByAppendingString:str2]stringByAppendingString:str]];
//                }
//                
//            }
//        }
//        [arr addObject:@"size_ratio_cyt_to_nuc"];
//        [arr addObject:@"Size_nuc"];
//        [arr addObject:@"Size_cyt"];
//    }
//    //Indexes for X and Y
//    [arr addObject:@"Size"];
//    [arr addObject:@"X"];
//    [arr addObject:@"Y"];
//    [arr addObject:@"Density"];
//    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS] = arr;
//    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS] = arr.copy;
//}

//Tie computations
-(NSInteger)channelsCreate:(NSIndexSet *)computations{
    NSArray *chans = self.mask.imageStack.channels;
    NSInteger countComps = [computations countOfIndexesInRange:NSMakeRange(0, 4)];
    if([self.mask isDual])
        countComps = [computations countOfIndexesInRange:NSMakeRange(4, 16)];
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:chans.count + 2];
    
    [arr addObject:@"CellId"]; countComps++;
    
    
    NSArray *strs1 = @[@"cell_",@"nuc_",@"cyt_", @"ratio_cyt_to_nuc_"];
    NSArray *strs2 = @[@"tot_",@"avg_",@"med_",@"std_"];
    
    for (NSString *str in chans) {
        for(int i = 0; i < 4; i++)
            if([computations containsIndex:i])
                [arr addObject:[strs1[0] stringByAppendingString:[strs2[i] stringByAppendingString:str]]];
        
        if([self.mask isDual]){
            for(int i = 4; i < 16; i++){
                if([computations containsIndex:i]){
                    [arr addObject:[[strs1[i/4] stringByAppendingString:strs2[i % 4]]stringByAppendingString:str]];
                }
            }
        }
    }
    if([self.mask isDual]){
        [arr addObject:@"size_ratio_cyt_to_nuc"];
        [arr addObject:@"Size_nuc"];
        [arr addObject:@"Size_cyt"];
        countComps += 3;
    }

    //Indexes for X and Y
    [arr addObject:@"Size"];
    [arr addObject:@"X"];
    [arr addObject:@"Y"];
    [arr addObject:@"Density"];
    countComps += 4;
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS] = arr;
    self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS] = arr.copy;
    
    return countComps;
}
-(void)extractDataForMaskOperation:(NSIndexSet *)computations{
    
    [self channelsCreate:computations];
    //Get the mask
    int * maskC = [self.mask mask];
    //Get the IMC data
    float ** allData = self.mask.imageStack.stackData;
    
    NSArray *imcChannels = self.mask.imageStack.channels;
    
    NSInteger rawChannels = imcChannels.count;
    NSInteger measuresPerChannel = computations.count;//isDual?16:4;
    NSInteger computedChannels = self.channels.count;
    
    NSInteger sizePicture = self.mask.imageStack.numberOfPixels;
    NSInteger segments = self.segmentedUnits;
    NSInteger width = self.mask.imageStack.width;
    NSInteger height = self.mask.imageStack.height;
    BOOL isDual = [self.mask isDual];
    
    [self prepData];
    float ** comp = self.computedData;
    
    //Add indexes of cells
    for (NSInteger i = 0; i < segments; i++)
        comp[0][i] = i + 1;
    
    //Get pixels for every object and sum of X and Y
    for (NSInteger i = 0; i < sizePicture; i++) {
        int val = maskC[i];
        int index = abs(val) - 1;
        if(val !=0){
            comp[computedChannels - 4][index] += 1.0f;
            //if(val < 0)_computedData[countNewChannels - 4][abs(val)-1]++;//Will change index
            if(isDual){
                if(val>0)comp[computedChannels- 5][index] += 1.0f;
                if(val<0)comp[computedChannels- 6][index] += 1.0f;
            }
            comp[computedChannels - 3][index] += (float)((i + width)%width);
            comp[computedChannels - 2][index] += (float)(i/width);
        }
    }
    
    
    
    //Generate holder structure
    float ** chelperArray = calloc(segments, sizeof(float *));
    float ** chelperArrayCyt = calloc(segments, sizeof(float *));
    float ** chelperArrayNuc = calloc(segments, sizeof(float *));
    for (NSInteger i = 0; i < segments; i++) {
        //Important, +1 because the first position contains a counter
        chelperArray[i] = calloc(sizePicture + 1, sizeof(float));
        chelperArrayCyt[i] = calloc(sizePicture + 1, sizeof(float));
        chelperArrayNuc[i] = calloc(sizePicture + 1, sizeof(float));
    }
    
    
    for (NSInteger c = 0; c < rawChannels; c++) {
        //Every cycle, reinitialize counter
        for (NSInteger i = 0; i < segments; i++) {
            chelperArray[i][0] = 1.0f;
            chelperArrayCyt[i][0] = 1.0f;
            chelperArrayNuc[i][0] = 1.0f;
        }
        
        //Get the channel buffer
        float * data = allData[c];
        //Cell the data and dump into object Arrays
        for (NSInteger i = 0; i < sizePicture; i++) {
            int cellId = maskC[i];
            int cellIndex = abs(cellId) - 1;
            if(cellIndex >= segments)continue;
            if(cellId != 0){
                chelperArray[cellIndex][(int)chelperArray[cellIndex][0]] = data[i];
                chelperArray[cellIndex][0]++;//Increase counter
            }
            if(cellId > 0){
                chelperArrayCyt[cellIndex][(int)chelperArrayCyt[cellIndex][0]] = data[i];//Use previous counter
                chelperArrayCyt[cellIndex][0]++;//Increase counter
            }
            if(cellId < 0){
                chelperArrayNuc[cellIndex][(int)chelperArrayNuc[cellIndex][0]] = data[i];
                chelperArrayNuc[cellIndex][0]++;//Increase counter
            }
        }
        //Calculations and add to _computedData buffer and clean buffer all at once
        for(NSInteger cursor = 0; cursor < segments; cursor++){
            
            float * channelData = chelperArray[cursor];
            float * cytChannelData = chelperArrayCyt[cursor];
            float * nucChannelData = chelperArrayNuc[cursor];
            
            float sum = [self sumForArray:channelData];
            float sumCyt = [self sumForArray:cytChannelData];
            float sumNuc = [self sumForArray:nucChannelData];
            
            NSInteger baseIndex = 1 + c * measuresPerChannel;
            
            NSInteger totalCount = channelData[0] -1.0f;
            NSInteger cytCount = cytChannelData[0] - 1.0f;//Removing the offsets -1.0f
            NSInteger nucCount = nucChannelData[0] - 1.0f;
            
            NSInteger internalCursor = 0;
            if([computations containsIndex:0]){ comp[baseIndex + internalCursor][cursor] = sum; internalCursor++; }
            if([computations containsIndex:1]){ comp[baseIndex + internalCursor][cursor] = totalCount == 0?0:sum/totalCount; internalCursor++; }
            if([computations containsIndex:2]){ comp[baseIndex + internalCursor][cursor] = totalCount == 0?0:[self medianForArray:channelData]; internalCursor++; }
            if([computations containsIndex:3]){ comp[baseIndex + internalCursor][cursor] = totalCount == 0?0:[self standardDeviationForArray:channelData withMean:sum/totalCount recalcMean:NO]; internalCursor++; }
            
            if([computations containsIndex:4]){ comp[baseIndex + internalCursor][cursor] = sumNuc; internalCursor++; }
            if([computations containsIndex:5]){ comp[baseIndex + internalCursor][cursor] = nucCount == 0?0:sumNuc/nucCount; internalCursor++; }
            if([computations containsIndex:6]){ comp[baseIndex + internalCursor][cursor] = nucCount == 0?0:[self medianForArray:nucChannelData]; internalCursor++; }
            if([computations containsIndex:7]){ comp[baseIndex + internalCursor][cursor] = nucCount == 0?0:[self standardDeviationForArray:nucChannelData withMean:sumNuc/nucCount recalcMean:NO]; internalCursor++; }
            
            if([computations containsIndex:8]){ comp[baseIndex + internalCursor][cursor] = sumCyt; internalCursor++; }
            if([computations containsIndex:9]){ comp[baseIndex + internalCursor][cursor] = cytCount == 0?0:sumCyt/cytCount; internalCursor++; }
            if([computations containsIndex:10]){ comp[baseIndex + internalCursor][cursor] = cytCount == 0?0:[self medianForArray:cytChannelData]; internalCursor++; }
            if([computations containsIndex:11]){ comp[baseIndex + internalCursor][cursor] = cytCount == 0?0:[self standardDeviationForArray:cytChannelData withMean:sumCyt/cytCount recalcMean:NO]; internalCursor++; }
            
            if([computations containsIndex:12]){
                if(sumNuc != 0)
                     comp[baseIndex + internalCursor][cursor] = sumCyt/sumNuc;
                internalCursor++;
            }
            if([computations containsIndex:13]){
                if(cytCount != 0 && sumNuc != 0 && nucCount != 0)
                    comp[baseIndex + internalCursor][cursor] = (sumCyt/cytCount)/(sumNuc/nucCount);
                internalCursor++;
            }
            if([computations containsIndex:14]){
                float med = [self medianForArray:nucChannelData];
                if(med != 0 && cytCount != 0 && nucCount != 0)
                    comp[baseIndex + internalCursor][cursor] = [self medianForArray:cytChannelData]/med;
                internalCursor++;
            }
            if([computations containsIndex:15]){
                if(nucCount != 0){
                    float std = [self standardDeviationForArray:nucChannelData withMean:sumNuc/nucCount recalcMean:NO];
                    if(std != 0 && cytCount != 0)
                        comp[baseIndex + internalCursor][cursor] = [self standardDeviationForArray:cytChannelData withMean:sumCyt/cytCount recalcMean:NO]/std;
                }
                internalCursor++;
            }
            if(isDual && comp[computedChannels- 5][cursor] != 0)
                comp[computedChannels- 7][cursor] = comp[computedChannels- 6][cursor]/comp[computedChannels- 5][cursor];
        }
    }
    
    for (NSInteger i = 0; i < segments; i++) {
        free(chelperArray[i]);
        free(chelperArrayNuc[i]);
        free(chelperArrayCyt[i]);
    }
    free(chelperArray);
    free(chelperArrayNuc);
    free(chelperArrayCyt);
    
    //Average X/Y to have centroids if Necessary
    for (int i = 0; i < segments; i++) {
        if(comp[computedChannels - 4] == 0)//Avoid dividing by 0
            continue;
        comp[computedChannels - 3][i] = comp[computedChannels - 3][i]/comp[computedChannels-4][i];
        comp[computedChannels - 2][i] = comp[computedChannels - 2][i]/comp[computedChannels-4][i];
    }
    //Neighbours
    int * neighbours = [self calculateNeighboursTouchingForMask:maskC width:width height:height];
    for (NSInteger i = 0; i < segments; i++)
        comp[computedChannels - 1][i] = neighbours[i];
    free(neighbours);
    [self saveData];
}
-(void)extractDataForMask:(NSIndexSet *)computations{
    BOOL wasLoaded = self.mask.imageStack.isLoaded;
    if(!wasLoaded)
        [self.mask.imageStack loadLayerDataWithBlock:nil];
    while (!self.mask.imageStack.isLoaded);
    [self extractDataForMaskOperation:computations];
    if(!wasLoaded){
        [self.mask.imageStack unLoadLayerDataWithBlock:nil];
        while(self.mask.imageStack.isLoaded);
    }
}
//-(void)extractDataForMaskOperation:(NSIndexSet *)computations{
//    
//    [self channelsCreate:computations];
//    //Get the mask
//    int * maskC = [self.mask mask];
//    //Get the IMC data
//    float ** allData = self.mask.imageStack.stackData;
//    
//    NSArray *imcChannels = self.mask.imageStack.channels;
//    NSInteger countChannels = imcChannels.count;
//    NSInteger countNewChannels = self.channels.count;
//    NSInteger sizePicture = self.mask.imageStack.numberOfPixels;
//    NSInteger segments = self.segmentedUnits;
//    NSInteger width = self.mask.imageStack.width;
//    NSInteger height = self.mask.imageStack.height;
//    BOOL isDual = [self.mask isDual];
//    
//    [self prepData];
//    float ** comp = self.computedData;
//    
//    //Add indexes of cells
//    for (NSInteger i = 0; i < segments; i++)
//        comp[0][i] = i + 1;
//    
//    //Get pixels for every object and sum of X and Y
//    for (NSInteger i = 0; i < sizePicture; i++) {
//        int val = maskC[i];
//        int index = abs(val) - 1;
//        if(val !=0){
//            comp[countNewChannels - 4][index] += 1.0f;
//            //if(val < 0)_computedData[countNewChannels - 4][abs(val)-1]++;//Will change index
//            if(isDual){
//                if(val>0)comp[countNewChannels- 5][index] += 1.0f;
//                if(val<0)comp[countNewChannels- 6][index] += 1.0f;
//            }
//            comp[countNewChannels - 3][index] += (float)((i + width)%width);
//            comp[countNewChannels - 2][index] += (float)(i/width);
//        }
//    }
//    
//    NSInteger measuresPerChannel = isDual?16:4;
//    
//    //Generate holder structure
//    float ** chelperArray = calloc(segments, sizeof(float *));
//    float ** chelperArrayCyt = calloc(segments, sizeof(float *));
//    float ** chelperArrayNuc = calloc(segments, sizeof(float *));
//    for (NSInteger i = 0; i < segments; i++) {
//        //Important, +1 because the first position contains a counter
//        chelperArray[i] = calloc(sizePicture + 1, sizeof(float));
//        chelperArrayCyt[i] = calloc(sizePicture + 1, sizeof(float));
//        chelperArrayNuc[i] = calloc(sizePicture + 1, sizeof(float));
//    }
//    
//    
//    for (NSInteger c = 0; c < countChannels; c++) {
//        NSLog(@"Channel %li %i", c, (int)isDual);
//        
//        //Every cycle, reinitialize counter
//        for (NSInteger i = 0; i < segments; i++) {
//            chelperArray[i][0] = 1.0f;
//            chelperArrayCyt[i][0] = 1.0f;
//            chelperArrayNuc[i][0] = 1.0f;
//        }
//        
//        //Get the channel buffer
//        float * data = allData[c];
//        //Cell the data and dump into object Arrays
//        for (NSInteger i = 0; i < sizePicture; i++) {
//            int cellId = maskC[i];
//            int cellIndex = abs(cellId) - 1;
//            if(cellIndex >= segments)continue;
//            if(cellId != 0){
//                chelperArray[cellIndex][(int)chelperArray[cellIndex][0]] = data[i];
//                chelperArray[cellIndex][0]++;//Increase counter
//            }
//            if(cellId > 0){
//                chelperArrayCyt[cellIndex][(int)chelperArrayCyt[cellIndex][0]] = data[i];//Use previous counter
//                chelperArrayCyt[cellIndex][0]++;//Increase counter
//            }
//            if(cellId < 0){
//                chelperArrayNuc[cellIndex][(int)chelperArrayNuc[cellIndex][0]] = data[i];
//                chelperArrayNuc[cellIndex][0]++;//Increase counter
//            }
//        }
//        //Calculations and add to _computedData buffer and clean buffer all at once
//        for(NSInteger cursor = 0; cursor < segments; cursor++){
//            
//            float * channelData = chelperArray[cursor];
//            float * cytChannelData = chelperArrayCyt[cursor];
//            float * nucChannelData = chelperArrayNuc[cursor];
//            
//            float sum = [self sumForArray:channelData];
//            float sumCyt = [self sumForArray:cytChannelData];
//            float sumNuc = [self sumForArray:nucChannelData];
//            
//            NSInteger baseIndex = 1 + c * measuresPerChannel;
//            
//            NSInteger totalCount = channelData[0] -1.0f;
//            NSInteger cytCount = cytChannelData[0] - 1.0f;//Removing the offsets -1.0f
//            NSInteger nucCount = nucChannelData[0] - 1.0f;
//            
//            comp[baseIndex][cursor] = sum;
//            comp[baseIndex + 1][cursor] = totalCount == 0?0:sum/totalCount;
//            comp[baseIndex + 2][cursor] = totalCount == 0?0:[self medianForArray:channelData];
//            comp[baseIndex + 3][cursor] = totalCount == 0?0:[self standardDeviationForArray:channelData withMean:comp[baseIndex + 1][cursor] recalcMean:NO];
//            
//            if (isDual) {
//                comp[baseIndex + 4][cursor] = sumNuc;
//                comp[baseIndex + 5][cursor] = nucCount == 0?0:sumNuc/nucCount;
//                comp[baseIndex + 6][cursor] = nucCount == 0?0:[self medianForArray:nucChannelData];
//                comp[baseIndex + 7][cursor] = nucCount == 0?0:[self standardDeviationForArray:nucChannelData withMean:comp[baseIndex + 4][cursor] recalcMean:NO];
//                
//                comp[baseIndex + 8][cursor] = sumCyt;
//                comp[baseIndex + 9][cursor] = cytCount == 0?0:sumCyt/cytCount;
//                comp[baseIndex + 10][cursor] = cytCount == 0?0:[self medianForArray:cytChannelData];
//                comp[baseIndex + 11][cursor] = cytCount == 0?0:[self standardDeviationForArray:cytChannelData withMean:comp[baseIndex + 8][cursor] recalcMean:NO];
//                
//                if(comp[baseIndex + 4][cursor] != 0)
//                    comp[baseIndex + 12][cursor] = comp[baseIndex + 8][cursor]/comp[baseIndex + 4][cursor];
//                if(comp[baseIndex + 5][cursor] != 0)
//                    comp[baseIndex + 13][cursor] = comp[baseIndex + 9][cursor]/comp[baseIndex + 5][cursor];
//                if(comp[baseIndex + 6][cursor] != 0)
//                    comp[baseIndex + 14][cursor] = comp[baseIndex + 10][cursor]/comp[baseIndex + 6][cursor];
//                if(comp[baseIndex + 7][cursor] != 0)
//                    comp[baseIndex + 15][cursor] = comp[baseIndex + 11][cursor]/comp[baseIndex + 7][cursor];
//            }
//            
//            if(isDual && comp[countNewChannels- 5][cursor] != 0)
//                comp[countNewChannels- 7][cursor] = comp[countNewChannels- 6][cursor]/comp[countNewChannels- 5][cursor];
//        }
//    }
//    
//    for (NSInteger i = 0; i < segments; i++) {
//        free(chelperArray[i]);
//        free(chelperArrayNuc[i]);
//    }
//    free(chelperArray);
//    free(chelperArrayNuc);
//    
//    //Average X/Y to have centroids if Necessary
//    for (int i = 0; i < segments; i++) {
//        if(comp[countNewChannels - 4] == 0)//Avoid dividing by 0
//            continue;
//        comp[countNewChannels - 3][i] = comp[countNewChannels - 3][i]/comp[countNewChannels-4][i];
//        comp[countNewChannels - 2][i] = comp[countNewChannels - 2][i]/comp[countNewChannels-4][i];
//    }
//    //Neighbours
//    int * neighbours = [self calculateNeighboursTouchingForMask:maskC width:width height:height];
//    for (NSInteger i = 0; i < segments; i++)
//        comp[countNewChannels - 1][i] = neighbours[i];
//    free(neighbours);
//    [self saveData];
//}

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
    return foundDiff;;
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
    
    float *vals = [self createImageForMaskWithCellData:self.computedData[index] maskOption:option maskType:maskType maskSingleColor:maskSingleColor];
    
    if(!vals || !settings)return;
    
    if(settings[5] == .0f){
        settings[5] = [self maxInBuffer:self.computedData[index]];
    }
    
    NSInteger pixs = self.mask.imageStack.numberOfPixels;
    
    for (NSInteger i = 0; i < pixs; i++) {
        float val = vals[i];
        if(settings[4] == 1.0f)val = logf(val);
        if(settings[4] == 2.0f)val = asinhf(val/5.0f);
        UInt8 bitValue = MIN(255, (val/(float)(settings[5] * settings[0]) * 255)*settings[2]);
        if(bitValue < settings[1] * 255)bitValue = 0;
        cachedValues[index][i] = bitValue;
    }
    if(settings[3] > 0)
        applyFilterToPixelData(cachedValues[index], self.mask.imageStack.width, self.mask.imageStack.height, 0, settings[3], 2, 1);
    
    if(vals)free(vals);
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
        [indexes addObject:[self statsForIndex:ind]];
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
    NSLog(@"Already %li %li", index, self.channels.count);
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
    NSLog(@"Already %li", alreadyInComp);
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
    [self clearCacheBuffers];
    [self saveData];
    free(old);
}
#pragma mark other operations on channels

-(void)removeChannelsWithIndexSet:(NSIndexSet *)indexSet{
    if(self.computedData && self.isLoaded){
        float ** new = calloc(self.channels.count - indexSet.count, sizeof(float *));
        NSInteger counter = 0;
        for (NSInteger i = 0; i < self.channels.count; i++) {
            if(![indexSet containsIndex:i]){
                new[counter] = self.computedData[i];
                counter++;
            }else{
                if(self.computedData[i])
                    free(self.computedData[i]);
            }
        }
        free(self.computedData);
        self.computedData = new;
        
        [self.originalChannels removeObjectsAtIndexes:indexSet];
        [self.channels removeObjectsAtIndexes:indexSet];
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

#pragma mark memmory management

-(void)release_computedData{
    if(self.computedData){
        for (NSInteger i = 0; i < self.channels.count; i++)
            if(self.computedData[i])
                free(self.computedData[i]);
        
        free(self.computedData);
        self.computedData = NULL;
    }
}

-(void)clearCacheBuffers{
    if(cachedValues != NULL){
        for (int i = 0; i < self.channels.count; i++)
            if(cachedValues[i] != NULL)
                free(cachedValues[i]);
        
        free(cachedValues);
        cachedValues = NULL;
    }
    if(cachedSettings != NULL){
        for (int i = 0; i < self.channels.count; i++)
            if(cachedSettings[i] != NULL)
                free(cachedSettings[i]);
        
        free(cachedSettings);
        cachedSettings = NULL;
    }
}
-(NSUInteger)usedMegaBytes{
    if(!self.computedData)return 0;
    return self.mask.numberOfSegments * self.channels.count * sizeof(float)/pow(2, 20);
}
-(void)dealloc{
    NSLog(@"_____DEALLOCING MASK COMPS");
    [self release_computedData];
    [self clearCacheBuffers];
}

@end
