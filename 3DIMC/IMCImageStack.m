//
//  IMCImageStack.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCImageStack.h"
#import "IMCImageGenerator.h"
#import "NSArray+Statistics.h"
#import "IMCPixelTraining.h"
#import "IMCPixelMap.h"
#import "IMCPixelClassification.h"
#import "IMCMasks.h"
#import "NSMutableArrayAdditions.h"
#import "IMCPanoramaWrapper.h"

@interface IMCImageStack(){
    UInt8 ** cachedValues;
    float ** cachedSettings;//MaxOffset, MinOffSet, Multiplication Factor, pixelFilterFactor, MAX
}

@end

@implementation IMCImageStack

-(NSString *)itemName{
    if (![self.jsonDictionary[JSON_DICT_ITEM_NAME]isEqualToString:@"UnknownFileName"]) {
        if(self.jsonDictionary[JSON_DICT_ITEM_NAME])
            return self.jsonDictionary[JSON_DICT_ITEM_NAME];
        
        if([(IMCPanoramaWrapper *)self.parent isPanorama])
            return [NSString stringWithFormat:@"%@ (%@, %@)", self.name ? self.name : @"Unknown ROI name", [(IMCPanoramaWrapper *)self.parent panoramaName], self.fileWrapper.itemName];
    }
    return self.fileWrapper.fileName;
}
-(NSString *)itemSubName{
    return @"";
}

#pragma mark Mask Relations

-(void)removeChild:(IMCNodeWrapper *)childNode{

    NSArray *keys = @[JSON_DICT_PIXEL_TRAININGS, JSON_DICT_PIXEL_MAPS, JSON_DICT_PIXEL_MASKS];
    for (NSString *key in keys)
        for (NSMutableDictionary *trainJson in [self.jsonDictionary[key]copy])
            if(childNode.jsonDictionary == trainJson){
                [self.jsonDictionary[key]removeObject:trainJson];
                NSFileManager *man = [NSFileManager defaultManager];
                if([man fileExistsAtPath:childNode.absolutePath])
                    [man removeItemAtPath:childNode.absolutePath error:NULL];
                if([[NSFileManager defaultManager]fileExistsAtPath:childNode.secondAbsolutePath])
                    [[NSFileManager defaultManager]removeItemAtPath:childNode.secondAbsolutePath error:NULL];
                
                //Clean up all the Cell profiler generated files
                if([key isEqualToString:JSON_DICT_PIXEL_MASKS]){
                    NSString *pref = trainJson[JSON_DICT_PIXEL_MASK_WHICH_MAP];
                    if(pref){
                        NSArray *filesInDir = [IMCLoader filesInDirectory:[NSURL fileURLWithPath:childNode.workingFolder]];
                        for (NSString *path in filesInDir) {
                            if([path hasPrefix:pref] && ![path hasSuffix:@".pmap"])
                                [[NSFileManager defaultManager]removeItemAtPath:[childNode.workingFolder stringByAppendingPathComponent:path] error:NULL];
                        }
                    }
                }
                
                childNode.parent = nil;
            }
}

-(void)initAllChildrenOfStack{
    
    NSArray *keys = @[JSON_DICT_PIXEL_TRAININGS, JSON_DICT_PIXEL_MAPS, JSON_DICT_PIXEL_MASKS];
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
                    if([key isEqualToString:JSON_DICT_PIXEL_TRAININGS])child = [[IMCPixelTraining alloc]init];
                    if([key isEqualToString:JSON_DICT_PIXEL_MAPS])child = [[IMCPixelMap alloc]init];
                    if([key isEqualToString:JSON_DICT_PIXEL_MASKS])child = [[IMCPixelClassification alloc]init];
                    child.jsonDictionary = trainJson;//Important this first
                    child.parent = self;
                }
            }
        }
    }
}
-(NSMutableArray *)pixelTrainings{
    return [self.children filterClass:NSStringFromClass([IMCPixelTraining class])].mutableCopy;
}
-(NSMutableArray *)pixelMaps{
    return [self.children filterClass:NSStringFromClass([IMCPixelMap class])].mutableCopy;
}
-(NSMutableArray *)pixelMasks{
    return [self.children filterClass:IMCPixelClassification.className].mutableCopy;
}

#pragma mark getters

-(NSSize)size{
    return NSMakeSize((float)self.width, (float)self.height);
}

-(NSUInteger)numberOfPixels{
    return self.width * self.height;
}

-(NSMutableArray *)channels{
    return [self.jsonDictionary valueForKey:JSON_DICT_IMAGE_CHANNELS];
}
-(void)setChannels:(NSMutableArray *)channels{
    [self.jsonDictionary setValue:channels forKey:JSON_DICT_IMAGE_CHANNELS];
}
-(NSMutableArray *)origChannels{
    return [self.jsonDictionary valueForKey:JSON_DICT_IMAGE_ORIG_CHANNELS];
}
-(void)setOrigChannels:(NSMutableArray *)origChannels{
    [self.jsonDictionary setValue:origChannels forKey:JSON_DICT_IMAGE_ORIG_CHANNELS];
}
-(NSString *)name{
    return [self.jsonDictionary valueForKey:JSON_DICT_IMAGE_NAME];
}
-(void)setName:(NSString *)name{
    [self.jsonDictionary setValue:name forKey:JSON_DICT_IMAGE_NAME];
}
-(NSUInteger)width{
    return [[self.jsonDictionary valueForKey:JSON_DICT_IMAGE_W]integerValue];
}
-(void)setWidth:(NSUInteger)width{
    [self.jsonDictionary setValue:[NSNumber numberWithInteger:width] forKey:JSON_DICT_IMAGE_W];
}
-(NSUInteger)height{
    return [[self.jsonDictionary valueForKey:JSON_DICT_IMAGE_H]integerValue];
}
-(void)setHeight:(NSUInteger)height{
    [self.jsonDictionary setValue:[NSNumber numberWithInteger:height] forKey:JSON_DICT_IMAGE_H];
}
-(CGRect)rectInPanorama{
    return [[self.jsonDictionary valueForKey:JSON_DICT_IMAGE_RECT_IN_PAN]rectValue];
}
-(NSMutableDictionary *)vanillaSettings{
    BOOL imcStack = [self isMemberOfClass:[IMCImageStack class]];
    return @{
             JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET:[NSNumber numberWithFloat:1.0f],
             JSON_DICT_CHANNEL_SETTINGS_OFFSET:[NSNumber numberWithFloat:.0f],
             JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER:[NSNumber numberWithFloat:imcStack?5.0f:1.0f],
             JSON_DICT_CHANNEL_SETTINGS_SPF:[NSNumber numberWithFloat:.0f],
             JSON_DICT_CHANNEL_SETTINGS_TRANSFORM:[NSNumber numberWithFloat:.0f]
             }.mutableCopy;
}
-(NSMutableArray *)channelSettings{
    if(![self.jsonDictionary valueForKey:JSON_DICT_IMAGE_CHANNEL_SETTINGS]
       || [[self.jsonDictionary valueForKey:JSON_DICT_IMAGE_CHANNEL_SETTINGS]count] != self.channels.count){
        NSMutableArray *arr = @[].mutableCopy;
        for (int i = 0; i < self.channels.count; i++) {
            [arr addObject:[self vanillaSettings]];
        }
        [self setChannelSettings:arr];
    }
    return [self.jsonDictionary valueForKey:JSON_DICT_IMAGE_CHANNEL_SETTINGS];
}
-(void)setChannelSettings:(NSMutableArray *)channelSettings{
    [self.jsonDictionary setValue:channelSettings forKey:JSON_DICT_IMAGE_CHANNEL_SETTINGS];
}

#pragma mark transforms

-(void)rotate:(float)rotation andTranslate:(float)x y:(float)y{
    float prevRot = [self.transform[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue];
    float prevX = [self.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue];
    float prevY = [self.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue];
    
    [self.transform setValue:
     [NSNumber numberWithFloat:prevRot + rotation]
                       forKey:JSON_DICT_IMAGE_TRANSFORM_ROTATION];
    [self.transform setValue:
     [NSNumber numberWithFloat:prevX + x]
                       forKey:JSON_DICT_IMAGE_TRANSFORM_OFFSET_X];
    [self.transform setValue:
     [NSNumber numberWithFloat:prevY - y]
                       forKey:JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y];
}

-(NSMutableDictionary *)transform{
    if(![self.jsonDictionary valueForKey:JSON_DICT_IMAGE_TRANSFORM]){
        NSMutableDictionary *dict = @{
                                      JSON_DICT_IMAGE_TRANSFORM_OFFSET_X:[NSNumber numberWithFloat:.0f],
                                      JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y:[NSNumber numberWithFloat:.0f],
                                      JSON_DICT_IMAGE_TRANSFORM_ROTATION:[NSNumber numberWithFloat:.0f],
                                      JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X:[NSNumber numberWithFloat:1.0f],
                                      JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y:[NSNumber numberWithFloat:1.0f]
                                      }.mutableCopy;
        
        [self setTransform:dict];
    }
    return [self.jsonDictionary valueForKey:JSON_DICT_IMAGE_TRANSFORM];
}

#pragma mark setters

-(void)setRectInPanorama:(CGRect)rectInPanorama{
    [self.jsonDictionary setValue:[NSValue valueWithRect:rectInPanorama] forKey:JSON_DICT_IMAGE_RECT_IN_PAN];
}
-(void)setJsonDictionary:(NSMutableDictionary *)jsonDictionary{
    [super setJsonDictionary:jsonDictionary];
    [self initAllChildrenOfStack];
}

-(void)setTransform:(NSMutableDictionary *)transform{
    [self.jsonDictionary setValue:transform forKey:JSON_DICT_IMAGE_TRANSFORM];
}

#pragma marks buffer allocation

-(void)allocateBufferWithPixels:(NSUInteger)pixels{
    if(self.stackData != NULL)
        free(self.stackData);
    self.stackData = NULL;
    
    if(self.stackData == NULL){
        self.stackData = (float **)calloc(self.channels.count, sizeof(float *));
        if(self.stackData)
            for (int i = 0; i < self.channels.count; i++) {
                self.stackData[i] = (float *)malloc(pixels * sizeof(float));
            }
    }
}

-(void)allocateCacheBuffersForIndex:(NSUInteger)index withPixels:(NSUInteger)pixels{
    if(cachedValues[index] != NULL)free(cachedValues[index]);
    cachedValues[index] = NULL;
    if(cachedValues[index] == NULL){
        cachedValues[index] = (UInt8 *)calloc(self.numberOfPixels, sizeof(UInt8));
    }
    
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

-(void)allocateBuffer{
    [self allocateBufferWithPixels:self.numberOfPixels];
}

#pragma mark caches and maxes

-(NSInteger)valueAtMilenile:(int)milenile_index forChannel:(NSInteger)channel{
    //TODO if image is very big this function crashes. Probably too much space to load in the stack
    float *data = self.usingCompensated ? self.compensatedData[channel] : self.stackData[channel];
    NSInteger * stack = calloc(self.numberOfPixels, sizeof(NSInteger));
    for (NSInteger i = 0; i < self.numberOfPixels; i++) {
        stack[i] = (NSInteger)data[i];
    }
    NSInteger res = milenile(stack, (int)self.numberOfPixels, milenile_index);
    free(stack);
    return res;
}

-(void)setAutoMaxForMilenile:(int)milenile andChannel:(NSInteger)channel{
    float valPer = [self valueAtMilenile:milenile forChannel:channel];
    if(valPer == .0f)return;

    [self getCachedBufferForIndex:channel];
    float max = cachedSettings[channel][5];
    if(max == .0f)
        cachedSettings[channel][0] = 1.0f;
    else
        cachedSettings[channel][0] = (float)valPer/max;
    
    self.channelSettings[channel][JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET] = [NSNumber numberWithFloat:valPer/max];
    [self recalculateChannelAtIndex:channel];
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
    NSInteger pixs = self.numberOfPixels;
    for (NSInteger i = 0; i < pixs; i++) {
        if(buffer[i] > max)max = buffer[i];
    }
    return max;
}

-(float)maxForIndex:(NSInteger)index{
    if(cachedSettings)
        if (cachedSettings[index])
            return cachedSettings[index][5];
    float ** data = self.usingCompensated ? self.compensatedData : self.stackData;
    if(data)
        if(data[index])
            return [self maxInBuffer:self.stackData[index]];
    return 255.0f;
}

-(void)recalculateChannelAtIndex:(NSInteger)index{
    
    float ** data = self.usingCompensated == YES? self.compensatedData : self.stackData;
    
    if(data == NULL && self.usingCompensated){
        [self compensateTheData];
        data = self.compensatedData;
    }else if(data == NULL){
        return;
    }
    
    float * settings = cachedSettings[index];
    float * vals = data[index];
    
    if(!vals || !settings)return;
    
    if(settings[5] == .0f){
        settings[5] = [self maxInBuffer:vals];
    }
    
    NSInteger pixs = self.numberOfPixels;
    
    float precalc = settings[2] * 255.0f/(settings[5] * settings[0]);
    for (NSInteger i = 0; i < pixs; i++) {
        float val = vals[i];
        if(settings[4] == 1.0f)val = logf(val);
        if(settings[4] == 2.0f)val = asinhf(val/5.0f);
        //UInt8 bitValue = MIN(255, (val/(float)(settings[5] * settings[0]) * 255)*settings[2]);
        UInt8 bitValue = MIN(255, val * precalc);
        if(bitValue < settings[1] * 255)bitValue = 0;
        cachedValues[index][i] = bitValue;
    }
    if(settings[3] > 0)
        applyFilterToPixelData(cachedValues[index], self.width, self.height, 0, settings[3], 4, 1);
}

-(NSUInteger)usedBytes{
    if(self.stackData != NULL){
        NSUInteger cached = 0;
        NSInteger pixs = self.numberOfPixels;
        
        for (int i = 0; i < self.channels.count; i++) {
            if(cachedValues != NULL){
                if(cachedValues[i] != NULL){
                    cached += pixs * sizeof(UInt8);
                }
            }
            if(self.compensatedData != NULL){
                if(self.compensatedData[i] != NULL){
                    cached += pixs * sizeof(float);
                }
            }
        }
        return pixs * sizeof(float) * self.channels.count + cached;
    }
    return 0;
}

-(NSUInteger)usedMegaBytes{
    if(self.stackData != NULL){
        return (float)[self usedBytes]/pow(2.0f, 20.0f);
    }
    return 0;
}

-(UInt8 *)getCachedBufferForIndex:(NSInteger)index{
    if(cachedValues == NULL || cachedSettings == NULL)
        [self allocateCacheBufferContainers];
    
    if(cachedValues[index] == NULL || cachedSettings[index] == NULL)
        [self allocateCacheBuffersForIndex:index withPixels:self.numberOfPixels];
    
    if([self compareCachedSettingsWithCurrentForIndex:index] == YES)
        [self recalculateChannelAtIndex:index];

    return cachedValues[index];
}

#pragma mark image buffer manipulation


-(void)rerackBuffers{
    NSInteger count = 0;
    for (NSInteger i = 0; i < self.channels.count; i++)if(self.stackData[i] != NULL)count++;

    float ** newHolder = (float **)malloc(count * sizeof(float *));
    float ** newSettings = (float **)malloc(count * sizeof(float *));
    UInt8 ** newCached = (UInt8 **)malloc(count * sizeof(UInt8 *));
    
    count = 0;
    for (NSInteger i = 0; i < self.channels.count; i++) {
        if(self.stackData[i] != NULL){
            newHolder[count] = self.stackData[i];
            newSettings[count] = cachedSettings[i];
            newCached[count] = cachedValues[i];
            count++;
        }
    }
    free(self.stackData);self.stackData = newHolder;
    free(cachedValues);cachedValues = newCached;
    free(cachedSettings);cachedSettings = newSettings;
}

-(void)removeChannelsWithIndexSet:(NSIndexSet *)indexes{
    if(self.stackData){
        [self allocateCacheBufferContainers];
        [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            if(self.stackData[index])
                free(self.stackData[index]);self.stackData[index] = NULL;
            if(cachedValues[index])
                free(cachedValues[index]);cachedValues[index] = NULL;
            if(cachedSettings[index])
               free(cachedSettings[index]);cachedSettings[index] = NULL;
        }];
        [self rerackBuffers];
        [[self channelSettings] removeObjectsAtIndexes:indexes];
        [self.origChannels removeObjectsAtIndexes:indexes];
        [self.channels removeObjectsAtIndexes:indexes];
    }
}

-(NSString *)concatChannels:(NSIndexSet *)indexSet{
    NSMutableString *str = @"".mutableCopy;
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        [str appendString:self.channels[index]];
        if(index != indexSet.lastIndex)[str appendFormat:@"_"];
    }];
    return [NSString stringWithString:str];
}

-(void)inserBuffer:(float *)buffer atIndex:(NSInteger)index nameChannel:(NSString *)name{
    if(!self.stackData)
        return;
    
    if(self.channels.count < index)
        return;
    
    float ** newHolder = (float **)malloc((self.channels.count + 1) * sizeof(float *));
    
    BOOL found = NO;
    for (NSInteger i = 0; i < self.channels.count; i++) {
        if(i == index){
            newHolder[i] = buffer;
            found = YES;
        }
        newHolder[i + found] = self.stackData[i];
    }
    if(!found)
        newHolder[self.channels.count] = buffer;
    if(self.stackData)
        free(self.stackData);
    self.stackData = newHolder;
    
    [[self channelSettings] insertObject:[self vanillaSettings] atIndex:index];
    [self clearCacheBuffers];
    
    [self.channels insertObject:name atIndex:index];
    [self.origChannels insertObject:name atIndex:index];
    [self allocateCacheBufferContainers];
}

-(void)addChannelsWithIndexSet:(NSIndexSet *)indexes toInlineIndex:(NSInteger)inLineIndex{
    if(self.channels.count < inLineIndex || self.channels.count < indexes.lastIndex)
        return;
    
    if(indexes.lastIndex >= self.channels.count)return;
    if(self.stackData){
        float * newChannel = (float *)calloc(self.numberOfPixels, sizeof(float));
        [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            for(NSInteger i = 0; i < self.numberOfPixels; i++)
                newChannel[i] += self.stackData[index][i];
        }];
        [self inserBuffer:newChannel atIndex:inLineIndex nameChannel:[@"Sum_" stringByAppendingString:[self concatChannels:indexes]]];
    }
}
-(void)multiplyChannelsWithIndexSet:(NSIndexSet *)indexes toInlineIndex:(NSInteger)inLineIndex{
    if(indexes.lastIndex >= self.channels.count || self.channels.count < inLineIndex)
        return;
    if(self.stackData){
        float * newChannel = (float *)calloc(self.numberOfPixels, sizeof(float));
        for(NSInteger i = 0; i < self.numberOfPixels; i++)newChannel[i] = 1.0f;
        [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
            for(NSInteger i = 0; i < self.numberOfPixels; i++)
                newChannel[i] *= self.stackData[index][i];
        }];
        [self inserBuffer:newChannel atIndex:inLineIndex nameChannel:[@"Multiplied_" stringByAppendingString:[self concatChannels:indexes]]];
    }
}

-(UInt8 **)preparePassBuffers:(NSArray *)indexSet{
    UInt8 ** pass = (UInt8 **)malloc(indexSet.count * sizeof(UInt8 *));
    
    for (NSNumber *num in indexSet) {
        if(num.integerValue >= self.channels.count)continue;
        UInt8 *chanBuffer = [self getCachedBufferForIndex:num.integerValue];
        pass[[indexSet indexOfObject:num]] = chanBuffer;
    }

    return pass;
}

#pragma mark Helpers Color Legend

-(NSArray *)maxesForIndexArray:(NSArray *)indexes{
    NSMutableArray *maxes = @[].mutableCopy;
    for (NSNumber *num in indexes) {
        if(num.integerValue >= self.channels.count)continue;
        if(cachedSettings){
            if(cachedSettings[num.integerValue])
                [maxes addObject:[NSNumber numberWithFloat:cachedSettings[num.integerValue][5]]];
        }
        else
            [maxes addObject:[NSNumber numberWithFloat:100.0f]];
    }
    return maxes;
}

-(NSArray *)maxOffsetsForIndexArray:(NSArray *)indexes{
    NSMutableArray *maxes = @[].mutableCopy;
    for (NSNumber *num in indexes) {
        if(num.integerValue >= self.channels.count)continue;
        if(cachedSettings){
            if(cachedSettings[num.integerValue])
                [maxes addObject:[NSNumber numberWithFloat:cachedSettings[num.integerValue][0]]];
        }
        else
            [maxes addObject:[NSNumber numberWithFloat:1.0f]];
    }
    return maxes;
}


//JSON dictionary getters

#pragma mark smart getters

-(NSInteger)ascertainIndexInStackForComputationChannel:(NSString *)channelName{
    NSArray *arr = [channelName componentsSeparatedByString:@"_"];
    NSArray *probes = @[@"tot", @"avg", @"med", @"std"];
    NSInteger comp = -1;
    for (NSString *sub in arr) {
        if([probes containsObject:sub])
            comp = [arr indexOfObject:sub];
    }
    if(comp >= 0 && arr.count >= comp + 2){
        NSString *interest = arr[comp + 1];
        NSArray *arraysToSearch = @[self.channels.copy, self.origChannels.copy];
        for (NSArray *arrS in arraysToSearch) {
            for (NSString *ch in arrS) {
                
                if([channelName isEqualToString:ch])
                    return [arrS indexOfObject:ch];
                
                if([interest isEqualToString:ch])
                    return [arrS indexOfObject:ch];
                
                if([ch rangeOfString:interest].location != NSNotFound)
                    if([ch rangeOfString:[interest stringByAppendingFormat:@"_%@", arr[comp + 2]]].location != NSNotFound)
                        return [arrS indexOfObject:ch];
            }
        }
    }
    return NSNotFound;
}

#pragma mark get masks

-(NSDictionary *)getMaskAtURL:(NSURL *)url{
    

    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *workingCopyFullPath = [[self.fileWrapper workingFolder]stringByAppendingPathComponent:url.lastPathComponent];
    NSString *workingCopyRel = [[self.fileWrapper workingFolderRealative]stringByAppendingPathComponent:url.lastPathComponent];
    
    [self.fileWrapper checkAndCreateWorkingFolder];
    
    if(![manager fileExistsAtPath:workingCopyFullPath]){
        NSError *error;
        [manager copyItemAtURL:url toURL:[NSURL fileURLWithPath:workingCopyFullPath] error:&error];
        if(error)
            NSLog(@"%@", error);
    }
    
    [self.fileWrapper.workingFolder stringByAppendingPathComponent:url.lastPathComponent];
    
    IMCPixelClassification *mask = [[IMCPixelClassification alloc]init];
    
    IMCPixelMap *map;
    for (IMCPixelMap *mapi in self.pixelMaps)
        if([[mapi.fileName substringToIndex:10]isEqualToString:[url.lastPathComponent substringToIndex:10]])
            map = mapi;
    
    mask.jsonDictionary = @{
                            JSON_DICT_ITEM_NAME:[@"SegMask " stringByAppendingString:url.lastPathComponent?url.lastPathComponent:@""],
                                  JSON_DICT_ITEM_HASH:[IMCUtils randomStringOfLength:30],
                                  JSON_DICT_ITEM_RELPATH:workingCopyRel,
                                  JSON_DICT_ITEM_FILETYPE:url.pathExtension,
                                  JSON_DICT_PIXEL_MASK_IS_NUCLEAR:[NSNumber numberWithBool:NO],
                                  JSON_DICT_PIXEL_MASK_IS_DUAL:[NSNumber numberWithBool:NO],
                                  JSON_DICT_PIXEL_MASK_IS_CELL:[NSNumber numberWithBool:YES],
                                  JSON_DICT_PIXEL_MASK_IS_DESIGNATED:[NSNumber numberWithBool:(self.pixelMasks.count == 0)]
                                  }.mutableCopy;
    if(map)
       [mask.jsonDictionary setObject:map.itemHash forKey:JSON_DICT_PIXEL_MASK_WHICH_MAP];
    
    //[self addPixelMask:mask];
    mask.parent = self;
    
    return mask.jsonDictionary;
}

#pragma mark compensation

-(float *)matrixNumbers:(NSString *)matrix{
    NSArray *lines = [matrix componentsSeparatedByString:@"\r"];
    float * numbers = malloc(pow(lines.count - 1, 2) * sizeof(float));
    
    NSInteger counter = 0;
    for (NSString *line in lines) {
        if(counter > 0){
            NSArray *comps = [line componentsSeparatedByString:@"\t"];
            for (NSInteger i = 1; i < comps.count; i++) {
                float value = [[comps objectAtIndex:i]floatValue];
                numbers[(counter - 1) * (lines.count - 1) + (i - 1)] = value;
            }
        }
        counter++;
    }
    return numbers;
}

-(NSArray *)isotopesList:(NSString *)matrix{
    NSArray *arrayLines = [matrix componentsSeparatedByString:@"\r"];
    if(arrayLines.count > 0){
        NSString *firstLine = arrayLines.firstObject;
        NSArray *list = [firstLine componentsSeparatedByString:@"\t"];
        return [list subarrayWithRange:NSMakeRange(1, list.count - 1)];
    }
    return nil;
}

-(NSInteger)indexOfChannel:(NSString *)chan inIsotopesList:(NSArray *)list{
    for (NSString *isot in list) {
        if ([chan rangeOfString:isot].length > 0) {
            return [list indexOfObject:isot];
        }
    }
    return -1;
}

-(void)compensateTheData{
    //[self getMetalForConjugates];
    if(self.compensatedData){
        for (NSInteger i = 0; i < self.channels.count; i++)
            if(self.compensatedData[i])
                free(self.compensatedData[i]);
    }
    self.compensatedData = (float **)calloc(self.channels.count, sizeof(float *));
    for (NSInteger i = 0; i < self.channels.count; i++)
        self.compensatedData[i] = calloc(self.numberOfPixels, sizeof(float));
    
    NSString *matrix = [self.fileWrapper.coordinator compMatrix];
    NSArray *listIsotopes = [self isotopesList:matrix];
    NSInteger countIsotopes = listIsotopes.count;
    float * matrixNumbers = [self matrixNumbers:matrix];
    
    NSInteger *indexes = calloc(countIsotopes, sizeof(NSInteger));
    NSInteger *reverseIndexes = calloc(countIsotopes, sizeof(NSInteger));
    for (int i = 0; i < countIsotopes; i++)
        reverseIndexes[i] = -1;
    
    for (NSString *chan in self.origChannels) {
        NSInteger i = [self indexOfChannel:chan inIsotopesList:listIsotopes];
        if(i<0)
            i = [self indexOfChannel:[self.channels objectAtIndex:[self.origChannels indexOfObject:chan]] inIsotopesList:listIsotopes];
        indexes[[self.origChannels indexOfObject:chan]] = i;
        if(i >= 0)
            reverseIndexes[i] = [self.origChannels indexOfObject:chan];
    }
//    
//    for (int i = 0; i < self.origChannels.count; i++)
//        printf("%i: %li\n", i, indexes[i]);
//    printf("\n\n");
//    for (int i = 0; i < countIsotopes; i++)
//        printf("%i: %li\n", i, reverseIndexes[i]);
    
    NSInteger channelsCount = self.channels.count;
    NSInteger pixelsCount = self.numberOfPixels;
    
    float * factors = calloc(countIsotopes, sizeof(float));
    NSLog(@"Start comp");
    for (NSInteger j = 0; j < channelsCount; j++) {
        
        NSInteger index = indexes[j];
        NSInteger stride = index * countIsotopes;
        
        for (NSInteger n = 0; n < countIsotopes; n++)
            if(index == n || reverseIndexes[n] < 0 || reverseIndexes[n] == j)
                factors[n] = .0f;
            else
                factors[n] = matrixNumbers[stride + indexes[n]];
        
        if(index < 0)
            memcpy(_compensatedData[j], _stackData[j], sizeof(float) * pixelsCount);
        
        else
            for (NSInteger i = 0; i < pixelsCount; i++) {
                float val = _stackData[j][i];
                if(val > 0){
                    for (NSInteger n = 0; n < countIsotopes; n++){
                        if(factors[n] > 0)
                            val -= _stackData[reverseIndexes[n]][i] * factors[n];
                        if(val <= 0){
                            val = 0;
                            break;
                        }
                    }
                }
                _compensatedData[j][i] = val;
            }
    }
    NSLog(@"Finished comp");
    free(indexes);
    free(reverseIndexes);
    free(factors);
}

-(void)setUsingCompensated:(BOOL)usingCompensated{
    _usingCompensated = usingCompensated;
    [self clearCacheBuffers];
}

#pragma mark get Transform

-(CGAffineTransform)affineTransformSuperCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper{
    float radians =  [IMCImageGenerator degressToRadians:[self.transform[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue]];
    NSDictionary *dictTransform = self.transform;
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, (widthSuper - (float)self.width)/2, (heightSuper -(float)self.height)/2);
    transform = CGAffineTransformTranslate(transform,
                                           dictTransform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]?
                                           [dictTransform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue]:0,
                                           dictTransform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]?
                                           [dictTransform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue]:0
                                           );
    
    transform = CGAffineTransformTranslate(transform, (float)self.width/2, (float)self.height/2);
    transform = CGAffineTransformRotate(transform, radians);
    transform = CGAffineTransformTranslate(transform, -(float)self.width/2, -(float)self.height/2);
    return transform;
}

-(NSInteger *)mapOfIndexesAfterAffineWithSuperCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper{

    //https://developer.apple.com/documentation/coregraphics/cgaffinetransform
    //x' = ax + cy + tx
    //y' = bx + dy + ty
    CGAffineTransform affine = [self affineTransformSuperCanvasW:widthSuper superCanvasH:heightSuper];
    NSInteger pixels = self.numberOfPixels;
    NSInteger leftPadding = (widthSuper - self.width)/2;
    NSInteger width = self.width;
    NSInteger height = self.height;
    CGFloat a = affine.a;
    CGFloat b = affine.b;
    CGFloat c = affine.c;
    CGFloat d = affine.d;
    CGFloat tx = affine.tx;
    CGFloat ty = affine.ty;
    NSInteger total = widthSuper * heightSuper;
    NSInteger * mapIndexes = calloc(total, sizeof(NSInteger));
    
    for (NSInteger i = 0; i < pixels; i++) {
        NSInteger x = i % width;
        NSInteger y = height - i / width;
        
        x = a * x + c * y + tx;
        y = b * x + d * y + ty;
        
        NSInteger newIndex = (heightSuper - y) * widthSuper + leftPadding + x;
        if(newIndex >= 0 && newIndex < total)
            mapIndexes[newIndex] = i;
    }
    return mapIndexes;
}

#pragma mark load unload

-(void)loadLayerDataWithBlock:(void (^)(void))block{
    if(![self canLoad])return;
    [self.fileWrapper loadLayerDataWithBlock:^{
        [super loadLayerDataWithBlock:block];
    }];
}
-(void)unLoadLayerDataWithBlock:(void (^)(void))block{
    [self clearBuffers];
    self.isLoaded = NO;
    self.fileWrapper.isLoaded = NO;
    [super unLoadLayerDataWithBlock:block];
}

#pragma mark memory clean up

-(void)clearCacheBuffers{
    if(cachedValues != NULL){
        for (int i = 0; i < self.channels.count; i++) {
            if(cachedValues[i] != NULL)free(cachedValues[i]);
        }
        free(cachedValues);
        cachedValues = NULL;
    }
    if(cachedSettings != NULL){
        for (int i = 0; i < self.channels.count; i++) {
            if(cachedSettings[i] != NULL)free(cachedSettings[i]);
        }
        free(cachedSettings);
        cachedSettings = NULL;
    }
}

-(void)clearBuffers{
    NSLog(@"Clearing Buffers");
    if(self.stackData != NULL){
        for (int i = 0; i < self.channels.count; i++) {
            if(self.stackData[i] != NULL){
                free(self.stackData[i]);
                self.stackData[i] = NULL;
            }
        }
        free(self.stackData);
        self.stackData = NULL;
    }
    if(self.compensatedData != NULL){
        for (int i = 0; i < self.channels.count; i++) {
            if(self.compensatedData[i] != NULL){
                free(self.compensatedData[i]);
                self.compensatedData[i] = NULL;
            }
        }
        free(self.compensatedData);
        self.compensatedData = NULL;
    }
    [self clearCacheBuffers];
}

#pragma mark memory management

-(void)dealloc{
    [self clearBuffers];
    NSLog(@"____DEALOCATING MEMORY");
}

@end
