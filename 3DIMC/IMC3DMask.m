//
//  IMC3DMask.m
//  3DIMC
//
//  Created by Raul Catena on 9/26/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMC3DMask.h"
#import "IMCLoader.h"
#import "IMCImageStack.h"
#import "IMCComputationOnMask.h"
#import "IMCImageGenerator.h"
#import "IMC3DHandler.h"
#import "IMC3DMaskComputations.h"
#import "flock.h"
#import "IMCMasks.h"
#import "NSArray+Statistics.h"

@interface IMC3DMask(){
    int * maskIds;
    UInt8 *** auxiliaryData;
    NSIndexSet *lastIndexSet;
}

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;

@end

@implementation IMC3DMask

-(instancetype)initWithLoader:(IMCLoader *)loader andHandler:(IMC3DHandler *)handler{
    self = [self init];
    if(self){
        self.coordinator = loader;
        self.threeDHandler = handler;
    }
    return self;
}
-(NSString *)itemName{
    return self.jsonDictionary[JSON_DICT_ITEM_NAME];
}
#pragma mark Mask Relations
-(void)setJsonDictionary:(NSMutableDictionary *)jsonDictionary{
    [super setJsonDictionary:jsonDictionary];
    [self initComputations];
}
-(void)initComputations{
    if(!_computationNodes)_computationNodes = @[].mutableCopy;
    for (NSMutableDictionary *trainJson in self.jsonDictionary[JSON_DICT_3DS_COMPUTATIONS]) {
        BOOL found = NO;
        for (IMC3DMaskComputations *comp in _computationNodes) {
            if(comp.jsonDictionary == trainJson)found = YES;
        }
        if(found == NO){
            IMC3DMaskComputations *train = [[IMC3DMaskComputations alloc]init];
            train.parent = self;
            train.jsonDictionary = trainJson;
            [_computationNodes addObject:train];
        }
    }
}

#pragma mark setters and getters

-(NSString *)itemSubName{
    return self.origin == MASK3D_VOXELS ? @"Voxel-based" : @"Mask-based";
}
-(NSArray *)components{
    return self.jsonDictionary[JSON_DICT_3DS_COMPONENTS];
}
-(void)setTheComponents:(NSArray *)components{
    self.jsonDictionary[JSON_DICT_3DS_COMPONENTS] = components;
}
-(NSMutableDictionary *)metadata{
    if(!self.jsonDictionary[JSON_DICT_3DS_METADATA])
        self.jsonDictionary[JSON_DICT_3DS_METADATA] = @{}.mutableCopy;
    return self.jsonDictionary[JSON_DICT_3DS_METADATA];
}
-(Mask3D_Type)type{
    return (Mask3D_Type)[self.metadata[JSON_DICT_3DS_METADATA_TYPE]integerValue];
}
-(void)setType:(Mask3D_Type)type{
    self.metadata[JSON_DICT_3DS_METADATA_TYPE] = @(type);
}
-(Mask3D_Origin)origin{
    return (Mask3D_Origin)[self.metadata[JSON_DICT_3DS_METADATA_ORIGIN]integerValue];
}
-(void)setOrigin:(Mask3D_Origin)origin{
    self.metadata[JSON_DICT_3DS_METADATA_ORIGIN] = @(origin);
}
-(NSInteger)channel{
    return [self.metadata[JSON_DICT_3DS_METADATA_CHANNEL]integerValue];
}
-(void)setChannel:(NSInteger)channel{
    self.metadata[JSON_DICT_3DS_METADATA_CHANNEL] = @(channel);
}
-(NSMutableArray *)channels{
    return self.metadata[JSON_DICT_3DS_METADATA_CHANNELS];
}
-(void)setChannels:(NSMutableArray *)channels{
    self.metadata[JSON_DICT_3DS_METADATA_CHANNELS] = channels;
}
-(NSInteger)substractChannel{
    return [self.metadata[JSON_DICT_3DS_METADATA_SUBST_CHANNEL]integerValue];
}
-(void)setSubstractChannel:(NSInteger)substractChannel{
    self.metadata[JSON_DICT_3DS_METADATA_SUBST_CHANNEL] = @(substractChannel);
}
-(NSInteger)expansion{
    return [self.metadata[JSON_DICT_3DS_METADATA_EXPANSION]integerValue];
}
-(void)setExpansion:(NSInteger)expansion{
    self.metadata[JSON_DICT_3DS_METADATA_EXPANSION] = @(expansion);
}
-(float)threshold{
    return [self.metadata[JSON_DICT_3DS_METADATA_THRESHOLD]floatValue];
}
-(void)setThreshold:(float)threshold{
    self.metadata[JSON_DICT_3DS_METADATA_THRESHOLD] = @(threshold);
}
-(float)stepWatershed{
    return [self.metadata[JSON_DICT_3DS_METADATA_STEP_WATERSHED]floatValue];
}
-(void)setStepWatershed:(float)stepWatershed{
    self.metadata[JSON_DICT_3DS_METADATA_STEP_WATERSHED] = @(stepWatershed);
}
-(NSInteger)minKernel{
    return [self.metadata[JSON_DICT_3DS_METADATA_MIN_KERNEL]integerValue];
}
-(void)setMinKernel:(NSInteger)minKernel{
    self.metadata[JSON_DICT_3DS_METADATA_MIN_KERNEL] = @(minKernel);
}
-(BOOL)sheepShaver{
    return [self.metadata[JSON_DICT_3DS_METADATA_SHEEP_SHAVER]boolValue];
}
-(void)setSheepShaver:(BOOL)sheepShaver{
    self.metadata[JSON_DICT_3DS_METADATA_SHEEP_SHAVER] = @(sheepShaver);
}
-(NSInteger)width{
    return [self.metadata[JSON_DICT_3DS_METADATA_WIDTH]integerValue];
}
-(void)setWidth:(NSInteger)width{
    self.metadata[JSON_DICT_3DS_METADATA_WIDTH] = @(width);
}
-(NSInteger)height{
    return [self.metadata[JSON_DICT_3DS_METADATA_HEIGHT]integerValue];
}
-(void)setHeight:(NSInteger)height{
    self.metadata[JSON_DICT_3DS_METADATA_HEIGHT] = @(height);
}
-(NSInteger)slices{
    return [self.metadata[JSON_DICT_3DS_METADATA_THICK]integerValue];
}
-(void)setSlices:(NSInteger)slices{
    self.metadata[JSON_DICT_3DS_METADATA_THICK] = @(slices);
}
-(void)setSegments:(NSInteger)segments{
    self.metadata[JSON_DICT_3DS_METADATA_SEGMENTS] = @(segments);
}
-(NSInteger)segments{
    return [self.metadata[JSON_DICT_3DS_METADATA_SEGMENTS]integerValue];
}
-(NSInteger)segmentedUnits{
    return self.segments;
}
-(NSString *)roiMask{
    return self.metadata[JSON_DICT_3DS_METADATA_ROI_MASK];
}
-(void)setRoiMask:(NSString *)roiMask{
    self.metadata[JSON_DICT_3DS_METADATA_ROI_MASK] = roiMask;
}


#pragma mark help functions for watershed

-(int)touchesId:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane{
    
    NSInteger test = 0;
    
    NSMutableDictionary *dic = @{}.mutableCopy;
    for (int cur = -1; cur < 2; cur+=2) {
        for (int type = 0; type < 3; type++) {
            switch (type) {
                case 0:
                    test = testIndex + plane * cur;
                    break;
                case 1:
                    test = testIndex + self.width * cur;
                    break;
                case 2:
                    test = testIndex + cur;
                    break;
                default:
                    break;
            }
            if(test > 0 && test < fullMaskLength)
                if(maskIds[test] > 0){
                    NSNumber *keyNum = @(maskIds[test]);
                    dic[keyNum] = dic[keyNum]?@([dic[keyNum]integerValue]+1):@(1);
                }
        }
    }
    if(dic.allKeys.count == 1)
        return [dic.allKeys.firstObject intValue];
    if(dic.allKeys.count > 1){
        return [[[NSSet setWithArray:dic.allKeys]anyObject]intValue];//0;

//        NSInteger max = 0;
//        NSNumber *key;
//        for (NSNumber *num in dic.allKeys) {
//            if([dic[num]integerValue]>max){
//                max = [dic[num]integerValue];
//                key = num;
//            }
//        }
//        return key.intValue;
    }
    
    return -1;
}

-(BOOL)hasZeroNeighbor:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    
    NSInteger test = 0;
    for (int cur = -1; cur < 2; cur+=2) {
        for (int type = 0; type < 3; type++) {
            switch (type) {
                case 0:
                    test = testIndex + plane * cur;
                    break;
                case 1:
                    test = testIndex + self.width * cur;
                    break;
                case 2:
                    test = testIndex + cur;
                    break;
                default:
                    break;
            }
            if(test > 0 && test < fullMaskLength)
                if(maskIds[test] == 0)
                    return YES;
            if(test < 0 || test >= fullMaskLength)
                return YES;
        }
    }
    return NO;
}

-(void)assignIdOld:(int)cellId toIndex:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    maskIds[testIndex] = cellId;
    int ratio = 1;
    BOOL foundId = YES;
    while(foundId == YES){
        foundId = NO;
        for (int a = 0; a < 3; a++) {
            for (int x = -ratio; x < ratio + 1; x+= a == 0? ratio * 2 : 1) {
                for (int y = -ratio; y < ratio + 1; y+= a == 1? ratio * 2 : 1) {
                    for (int z = -ratio; z < ratio + 1; z+= a == 2? ratio * 2 : 1) {
                        NSInteger index = testIndex + z * plane + y * width + x;
                        if(index >= 0 && index < fullMaskLength && index != testIndex){
                            if (maskIds[index] == -1) {
                                if([self touchesId:index fullMaskLength:fullMaskLength planLength:plane] != cellId){
                                    maskIds[index] = cellId;
                                    foundId = YES;
                                }
                            }
                        }
                    }
                }
            }
        }
        ratio++;
    }
}
-(void)assignId:(int)cellId toIndex:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    maskIds[testIndex] = cellId;
    
    NSMutableArray *arr = @[].mutableCopy;
    NSNumber *inScopeNumber = @(testIndex);
    do{
        NSInteger val = inScopeNumber.integerValue;
        NSInteger candidates[6] = {val - width,
                                    val + width,
                                    val - 1,
                                    val + 1,
                                    val - plane,
                                    val + plane
                            };
        for (int m = 0; m < 6;  m++){
            if(candidates[m] > 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == -1){
                    maskIds[candidates[m]] = cellId;
                    [arr addObject:@(candidates[m])];
                }
        }
        
        inScopeNumber = [arr lastObject];
        [arr removeLastObject];
    }
    while (inScopeNumber);
}
-(void)recurseGiveId:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane cellId:(int)cellId width:(NSInteger)width{
    
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            for (int k = -1; k < 2; k++) {
                NSInteger test = testIndex + k * plane + j * width + i;
                if(abs(i) == 1 && abs(j) == 1 && abs(k) == 1)
                    continue;
                if(test > 0 && test < fullMaskLength)
                    if(maskIds[test] == -1 && testIndex != test){
                        maskIds[test] = cellId;
                        [self recurseGiveId:test fullMaskLength:fullMaskLength planLength:plane cellId:cellId width:width];
                    }
            }
        }
    }
    maskIds[testIndex] = cellId;
}
-(int)checkCandidatesOld:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    int candidates = 0;
    int ratio = 1;
    BOOL found = NO;
    do{
        found = NO;
        for (int a = 0; a < 3; a++) {
            for (int x = -ratio; x < ratio + 1; x+= a == 0? ratio * 2 : 1) {
                for (int y = -ratio; y < ratio + 1; y+= a == 1? ratio * 2 : 1) {
                    for (int z = -ratio; z < ratio + 1; z+= a == 2? ratio * 2 : 1) {
                        NSInteger index = testIndex + z * plane + y * width + x;
                        if(index >= 0 && index < fullMaskLength){
                            if (maskIds[index] == -1) {
                                if([self touchesId:index fullMaskLength:fullMaskLength planLength:plane] == -1){
                                    candidates++;
                                    found = YES;
                                }
                            }
                        }
                    }
                }
            }
        }
        ratio++;
    }while (found);
    
    return candidates;
}
-(int)checkCandidates:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width once:(BOOL)once{
    int candidatesCount = 0;
    
    NSMutableArray *arr = @[].mutableCopy;
    NSMutableArray *visited = @[].mutableCopy;
    
    NSNumber *inScopeNumber = @(testIndex);
    do{
        NSInteger val = inScopeNumber.integerValue;
        NSInteger candidates[6] = {val - width,
            val + width,
            val - 1,
            val + 1,
            val - plane,
            val + plane
        };
        for (int m = 0; m < 6;  m++){
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == -1){
                    maskIds[candidates[m]] = -2;
                    //if(![arr containsObject:@(candidates[m])])
                    [arr addObject:@(candidates[m])];
                }
            
        }
        candidatesCount++;
        [visited addObject:inScopeNumber];
        inScopeNumber = [arr lastObject];
        [arr removeLastObject];
    }
    while (inScopeNumber);
    
    if(!once)
        for (NSNumber *num in visited)
            maskIds[num.integerValue] = -1;
    
    return candidatesCount;
}
-(int)recursiveCheckCandidates:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            for (int k = -1; k < 2; k++) {
                if(abs(i) == 1 && abs(j) == 1 && abs(k) == 1)
                    continue;
                NSInteger test = testIndex + k * plane + j * width + i;
                if(test > 0 && test < fullMaskLength)
                    if(maskIds[test] == -1 && testIndex != test){
                        maskIds[test] = 0;
                        return 1 + [self recursiveCheckCandidates:test fullMaskLength:fullMaskLength planLength:plane width:width];
                    }
            }
        }
    }
    return 0;
}

-(void)resetNegs:(NSInteger)allLength{
    for (NSInteger i = 0; i < allLength; i++)
        if(maskIds[i] < 0)
            maskIds[i] = 0;
}
-(void)invertNegs:(NSInteger)allLength{
    for (NSInteger i = 0; i < allLength; i++)
        if(maskIds[i] < 0)
            maskIds[i] = -maskIds[i];
}

-(void)extractMaskFromRender{
    IMC3DHandler *handler = self.threeDHandler;
    
    self.width = handler.width;
    self.height = handler.height;
    self.slices = handler.images;
    
    self.roiMask = NSStringFromRect(self.threeDHandler.interestProportions);
    
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  self.slices;
    NSInteger channel = self.channel;
    NSInteger schannel = self.substractChannel;
    
    float final = self.threshold;

    [self releaseMask];
    
    maskIds = calloc(fullMask, sizeof(int));
    bool * mask = self.threeDHandler.showMask;
    
    if(self.type == MASK3D_WATERSHED){
        int cellId = 1;
        for (float analyze = 1.0f; analyze > final; analyze -= self.stepWatershed) {
            //Add Values
            float analyzeAdded = analyze * 255;
            NSLog(@"%f step", analyzeAdded);
            
            //        if(schannel > 0)
            //            analyzeAdded *= (1 - analyze);
            
            for (NSInteger i = 0; i < handler.images; i++) {
                NSInteger offset = allLength * i;
                if(handler.allBuffer[i]){
                    if(handler.allBuffer[i][channel]){
                        for (NSInteger j = 0; j < allLength; j++){
                            if(mask[j] == false)
                                continue;
                            if(maskIds[offset + j] == -1){
                                int neigh = [self touchesId:offset + j fullMaskLength:fullMask planLength:allLength];
                                if(neigh > 0)
                                    maskIds[offset + j] = neigh;
                            }
                            if(maskIds[offset + j] == 0){
                                UInt8 val = handler.allBuffer[i][channel][j];
                                if(schannel > 0 && handler.allBuffer[i][schannel])
                                    val -= handler.allBuffer[i][schannel][j];
                                if(val >= analyzeAdded){
                                    maskIds[offset + j] = [self touchesId:offset + j fullMaskLength:fullMask planLength:allLength];
                                }
                            }
                        }
                    }
                }
            }
            for (NSInteger i = 0; i < handler.images; i++) {
                NSInteger offset = allLength * i;
                if(handler.allBuffer[i])
                    if(handler.allBuffer[i][channel])
                        for (NSInteger j = 0; j < allLength; j++){
                            if(mask[j] == false)
                                continue;
                            if(maskIds[offset + j] == -1){
                                int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:allLength width:self.width once:NO];
                                if(qual >= self.minKernel){//Promote all
                                    [self assignId:cellId toIndex:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                                    cellId++;
                                }
                            }
                        }

            }
        }
        NSLog(@"Assigned %i", cellId);
        self.segments = cellId - 1;
    }
    if(self.type == MASK3D_THRESHOLD || self.type == MASK3D_THRESHOLD_SEGMENT){
        float analyze = self.threshold * 255;
        
        for (NSInteger i = 0; i < handler.images; i++) {
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++)
                        if(maskIds[offset + j] == 0){
                            UInt8 val = handler.allBuffer[i][channel][j];
                            if(schannel > 0 && handler.allBuffer[i][schannel])
                                val -= handler.allBuffer[i][schannel][j];
                            if(val >= analyze)
                                maskIds[offset + j] = -1;
                        }
        }
        int cellId = 1;
        for (NSInteger i = 0; i < handler.images; i++) {
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++)
                        if(maskIds[offset + j] == -1){
                            int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:allLength width:self.width once:NO];
                            if(qual >= self.minKernel){//Promote all
                                [self assignId:self.type == MASK3D_THRESHOLD_SEGMENT?cellId:1 toIndex:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                                NSLog(@"ID %i", cellId);
                                cellId++;
                            }
                        }
        }
        NSLog(@"Assigned %i", cellId);
        self.segments = cellId - 1;
    }
    //Reset negative values
    [self resetNegs:fullMask];
    
    //Expand
    [self expand];
    
    //Prepare the 3D buffer handler
    [self passToHandler];
    
    //Load up node
    self.isLoaded = YES;
    
    //Save file with mask
    [self saveMaskData];
}

-(void)expand{
    
    IMC3DHandler *handler = self.threeDHandler;
    
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  handler.images;
    NSInteger width = self.width;
    
    for (NSInteger i = 0; i < self.expansion; i++) {
        
        NSInteger zpass = i % 2 == 0 ? fullMask : allLength;
        
        for (NSInteger j = 0; j < fullMask; j++) {

            int val = maskIds[j];
            if(val > 0){
                NSInteger candidates[6] = {
                    j - width,
                    j + width,
                    j - 1,
                    j + 1,
                    j - zpass,
                    j + zpass
                };
                for (int m = 0; m < 6;  m++)
                    if(candidates[m] >= 0 && candidates[m] < fullMask)
                        if(maskIds[candidates[m]] == 0)
                            maskIds[candidates[m]] = -val;
            }
        }
        [self invertNegs:fullMask];
    }
    
}

-(void)passToHandler{
    if(maskIds){
        NSInteger allLength = self.width * self.height;
        //NSInteger fullMaskLength = allLength * self.slices;
        [self.threeDHandler startBufferForImages:self.threeDHandler.loader.inOrderImageWrappers channels:1 width:self.width height:self.height];
        
        int randomColors = 12;
        float pre[randomColors];
        float pass = .95f/randomColors;
        for (int i = 0; i < randomColors; i++) {
            pre[i] = (0.05f + pass * i) * 255;
        }
        self.threeDHandler.interestProportions = NSRectFromString(self.roiMask);
        if(self.threeDHandler.allBuffer)
            for (NSInteger i = 0; i < self.threeDHandler.images; i++) {
                
                NSInteger offSet = allLength * i;
                    if(self.threeDHandler.allBuffer[i][0] != NULL)
                        free(self.threeDHandler.allBuffer[i][0]);
                    self.threeDHandler.allBuffer[i][0] = calloc(allLength, sizeof(float));
                    for (NSInteger j = 0; j < allLength; j++){
                        int maskId = maskIds[offSet + j];
                        if(maskId > 0){
                            if(self.threeDHandler.allBuffer[i]){
                                //if([self hasZeroNeighbor:offSet + j fullMaskLength:fullMaskLength planLength:allLength width:self.width])
                                    self.threeDHandler.allBuffer[i][0][j] = pre[maskId%randomColors];
                        }
                    }
                }
            }
        [self.threeDHandler meanBlurModelWithKernel:3 forChannels:[NSIndexSet indexSetWithIndex:0] mode:self.blurMode];
    }
}

-(void)releaseMask{
    if(maskIds){
        NSLog(@"Releasing mask 3D Memory");
        free(maskIds);
        maskIds = NULL;
    }
}
-(NSString *)pathFile{
    [self.coordinator checkAndCreateWorkingDirectory];
    return  [[self.coordinator.workingDirectoryPath stringByAppendingPathComponent:self.itemHash]stringByAppendingPathExtension:@".3mask"];
}

-(NSString *)pathCellDataFile{
    [self.coordinator checkAndCreateWorkingDirectory];
    return  [[self.coordinator.workingDirectoryPath stringByAppendingPathComponent:self.itemHash]stringByAppendingPathExtension:@".cbin"];
}

#pragma mark save
-(void)saveMaskData{
    if(maskIds){
        NSInteger elems = self.slices * self.width * self.height;
        NSInteger count = elems * sizeof(int);
        int * compMask = malloc(count);
        
        int cursorComp = 0;
        int scopeValue = maskIds[0], inRow = 1;
        for (NSInteger i = 1; i < elems; i++) {
            if(maskIds[i] == scopeValue)
                inRow++;
            else{
                compMask[cursorComp] = inRow;
                compMask[cursorComp + 1] = scopeValue;
                cursorComp += 2;
                inRow = 1;
                scopeValue = maskIds[i];
            }
        }
        compMask = realloc(compMask, cursorComp * sizeof(int));
        NSData *data = [NSData dataWithBytes:compMask length:cursorComp * sizeof(int)];
        NSError *error = nil;
        NSString *path = [self pathFile];
        [data writeToFile:path options:NSDataWritingAtomic error:&error];
            if(error)
                NSLog(@"Write returned error: %@", [error localizedDescription]);
    }
}



-(void)saveData{
    
    NSMutableData *data = [NSMutableData data];
    NSInteger channels = self.channels.count;
    
    for (NSInteger i = 0; i < channels; i++)
        if(self.computedData[i])
            [data appendBytes:self.computedData[i] length:self.segments * sizeof(float)];
    
    NSError *error = nil;
    NSString *path = [self pathCellDataFile];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    if(error)
        NSLog(@"Write returned error: %@", [error localizedDescription]);
}

-(void)deleteSelf{
    NSString *path = [self pathFile];
    NSError *error = nil;
    [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    if(error)
        NSLog(@"Remove returned error: %@", [error localizedDescription]);
    
    path = [self pathCellDataFile];
    [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    if(error)
        NSLog(@"Remove returned error: %@", [error localizedDescription]);
    [self.coordinator remove3DNode:self];
}
-(void)loadLayerDataWithBlock:(void (^)())block{
    
    NSString *path = [self pathFile];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if(data){
        [self releaseMask];
        NSInteger elems = self.slices * self.width * self.height;
        NSInteger count = elems * sizeof(int);
        maskIds = malloc(count);
        
        NSInteger counter = 0;
        int reps;
        int val;
        size_t intSize = sizeof(int);
        int elemsReceiver = (int)data.length / intSize;
        size_t stride = intSize * 2;
        for (NSInteger i = 0, j = 0; i < elemsReceiver; i+=2, j += stride) {
            [data getBytes:&reps range:NSMakeRange(j, intSize)];
            [data getBytes:&val range:NSMakeRange(j + intSize, intSize)];
            for (NSInteger j = 0; j < reps; j++) {
                maskIds[counter] = val;
                counter++;
            }
        }
    }
    [self passToHandler];
    self.isLoaded = YES;
    
    
    NSData *cellData = [NSData dataWithContentsOfFile:[self pathCellDataFile]];
    if(cellData){
        NSInteger channelsCount = self.channels.count;
        NSInteger units = self.segments;
        
        if(data.length < channelsCount * units * sizeof(float)){
            dispatch_async(dispatch_get_main_queue(), ^{[General runAlertModalWithMessage:@"File corrupted"];});
            return;
        }
        
        [self allocateComputedData];
        
        NSInteger counter = 0;
        float *allBytes = (float *)cellData.bytes;
        for (NSInteger i = 0; i < channelsCount; i++) {
            for (NSInteger j = 0; j < units; j++) {
                self.computedData[i][j] = allBytes[counter];
                counter ++;
            }
        }
    }else{
        NSInteger input = [General runAlertModalAreYouSureWithMessage:
                           @"No channel data associated to this mask.\
                           Would you like to extract the channel data for this 3D mask? This may take a few minutes."];
        
        if(input == NSAlertFirstButtonReturn)
            [self extractCellData];
    }    
}
-(void)unLoadLayerDataWithBlock:(void (^)())block{
    [self releaseMask];
    [self clearComputedData];
    [super unLoadLayerDataWithBlock:block];
}

#pragma mark extract cell data

-(NSInteger)depthFromVoxel:(NSInteger)voxelIndex width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger cellId = maskIds[voxelIndex];
    maskIds[voxelIndex] = -maskIds[voxelIndex];
    
    NSMutableArray *voxels = @[].mutableCopy;
    NSMutableArray *processing = @[].mutableCopy;
    
    NSNumber * testVoxel = @(voxelIndex);
    
    while (testVoxel) {
        NSInteger val = testVoxel.integerValue;
        NSInteger candidates[6] = {val - width,
            val + width,
            val - 1,
            val + 1,
            val - planeLength,
            val + planeLength
        };
        for (int m = 0; m < 6;  m++){
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == cellId){
                    maskIds[candidates[m]] = -maskIds[candidates[m]];
                    [processing addObject:@(candidates[m])];
                }
        }
        [voxels addObject:testVoxel];
        testVoxel = [processing lastObject];
        [processing removeLastObject];
    }
    NSInteger basePlane = voxelIndex/planeLength;
    NSInteger maxDepth = basePlane;
    for (NSNumber *num in voxels) {
        NSInteger vox = num.integerValue;
        maxDepth = MAX(vox/planeLength, maxDepth);
        maskIds[vox] = -maskIds[vox];
    }
    
    return maxDepth;
}

-(NSInteger)maxDepthInPlane:(NSInteger)plane width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger planeOffset = planeLength * plane;
    
    NSInteger maxDepth = 0;
    NSMutableArray *seen = @[].mutableCopy;
    for (NSInteger i = 0; i < planeLength; i++) {
        NSInteger index = planeOffset + i;
        if(maskIds[index] > 0){
            if(![seen containsObject:@(maskIds[index])]){
                [seen addObject:@(maskIds[index])];
                NSInteger depth = [self depthFromVoxel:index width:width planeLength:planeLength totalMask:fullMaskLength];
                maxDepth = MAX(maxDepth, depth);
            }
        }
    }
    return maxDepth;
}

-(NSArray *)collectVoxelsForVoxelIndex:(NSInteger)voxelIndex width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger cellId = maskIds[voxelIndex];
    maskIds[voxelIndex] = -maskIds[voxelIndex];
    
    NSMutableArray *voxels = @[].mutableCopy;
    NSMutableArray *processing = @[].mutableCopy;
    
    NSNumber * testVoxel = @(voxelIndex);
    
    while (testVoxel) {
        NSInteger val = testVoxel.integerValue;
        NSInteger candidates[6] = {val - width,
            val + width,
            val - 1,
            val + 1,
            val - planeLength,
            val + planeLength
        };
        for (int m = 0; m < 6;  m++){
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == cellId){
                    maskIds[candidates[m]] = -maskIds[candidates[m]];
                    [processing addObject:@(candidates[m])];
                }
        }
        [voxels addObject:testVoxel];
        testVoxel = [processing lastObject];
        [processing removeLastObject];
    }
    return voxels;
}
-(void)clearComputedData{
    if(self.computedData){
        NSInteger channels = [self.threeDHandler.loader maxChannels];
        for (NSInteger c = 0; c < channels; c++) {
            if(self.computedData[c]){
                free(self.computedData[c]);
                self.computedData[c] = NULL;
            }
        }
        free(self.computedData);
        self.computedData = NULL;
    }
}
-(void)allocateComputedData{
    
    [self clearComputedData];
    
    NSInteger channels = [[self channels]count];
    self.computedData = malloc(channels * sizeof(float *));
    for (NSInteger c = 0; c < channels; c++)
        self.computedData[c] = calloc(self.segments, sizeof(float));
}

-(void)loadSlice:(IMCImageStack *)stack toBuffer:(UInt8 **)auxBuffer canvasW:(NSInteger)maxWidth canvasH:(NSInteger)maxHeight channels:(NSInteger)channelsExtraction planeLength:(NSInteger)planeLength{
    
    NSMutableArray *allChannels = @[].mutableCopy;
    for (int z = 0; z < stack.channels.count; z++)
        [allChannels addObject:@(z)];
    
    for (NSInteger c = 0; c < channelsExtraction; c++) {
        CGImageRef ref = [IMCImageGenerator whiteRotatedBufferForImage:stack atIndex:c superCanvasW:maxWidth superCanvasH:maxHeight];
        UInt8 *buf = [IMCImageGenerator bufferForImageRef:ref];
        for(NSInteger pix = 0, pos = 0; pix < planeLength; pix++, pos += 4)
            auxBuffer[c][pix] += buf[pos];
        CGImageRelease(ref);
        free(buf);
    }
}

-(void)extractCellData{
    [self openIfNecessaryAndPerformBlock:^{
        
        NSInteger planeLength = self.width * self.height;
        NSInteger fullMask = planeLength *  self.slices;
        NSInteger maxWidth = [self.threeDHandler.loader maxWidth] * 1.5;
        
        NSInteger channelsExtraction = [self.threeDHandler.loader maxChannels];
        for (IMCImageStack *stack in self.threeDHandler.loader.inOrderImageWrappers) {
            if(stack.channels.count < channelsExtraction){
                [General runAlertModalWithMessage:@"An image does not have as many channels as the first image on top of the stack. Can't proceed"];
                return;
            }
        }
        NSMutableArray *channelStrings = [[(IMCImageStack *)self.threeDHandler.loader.inOrderImageWrappers.firstObject channels]mutableCopy];
        [channelStrings addObjectsFromArray:@[@"X", @"Y", @"Z", @"Density", @"Size"]];
        [self setChannels:channelStrings];
        
        
        NSInteger total = self.segments;
        if(total == 0){
            for (NSInteger i = 0; i < fullMask; i++)
                if(maskIds[i] > total)
                    total = maskIds[i];
            
            if(total > 0)
                self.segments = total - 1;
            else
                return;
        }

        [self allocateComputedData];
        auxiliaryData = calloc(self.slices, sizeof(UInt8 **));
        NSLog(@"Segments %li ", self.segments);
        
        dispatch_queue_t slicer = dispatch_queue_create("slicer", NULL);
        dispatch_async(slicer, ^{
            
            NSInteger end = 0;
            for (NSInteger p = 0; p < self.slices; p++) {
                //Find until where deepest voxel falls
                NSInteger lastTouchedPlane = [self maxDepthInPlane:p width:self.width planeLength:planeLength totalMask:fullMask];
                
                //Define range to have open only relevant slices
                NSInteger begg = [self.threeDHandler internalSliceIndexForExternal:p];
                end = MAX(end, [self.threeDHandler internalSliceIndexForExternal:lastTouchedPlane]);
                
                NSLog(@"Layer %li goes to %li internals %li | %li", p, lastTouchedPlane, begg, end);
                
                //Open relevant slices and form auxiliary buffer
                for (NSInteger l = begg; l < end + 1; l++){
                    
                    NSInteger ext = [self.threeDHandler externalSliceIndexForInternal:l];
                    
                    if(!auxiliaryData[ext]){
                        NSLog(@"Load external %li", ext);
                        auxiliaryData[ext] = calloc(channelsExtraction, sizeof(UInt8 *));
                        for(NSInteger c = 0; c < channelsExtraction; c++)
                            auxiliaryData[ext][c] = calloc(planeLength, sizeof(UInt8));
                        
                        NSArray *internals = [self.threeDHandler indexesArranged][ext];
                        for(NSNumber *internal in internals){
                            IMCImageStack *stack = self.threeDHandler.loader.inOrderImageWrappers[internal.integerValue];
                            [stack openIfNecessaryAndPerformBlock:^{
                                [self loadSlice:stack toBuffer:auxiliaryData[ext] canvasW:maxWidth canvasH:maxWidth channels:channelsExtraction planeLength:planeLength];
                            }];
                        }
                    }
                }
                //Close unnecessary slices
                for (NSInteger s = 0; s < p; s++) {
                    if(auxiliaryData[s]){
                        NSLog(@"Remove external %li", s);
                        for (NSInteger c = 0; c < channelsExtraction; c++)
                            if(auxiliaryData[s][c]){
                                free(auxiliaryData[s][c]);
                                auxiliaryData[s][c] = NULL;
                            }
                        free(auxiliaryData[s]);
                        auxiliaryData[s] = NULL;
                    }
                }
                
                
                NSInteger offsetPlane = p * planeLength;
                NSInteger upperLimit = offsetPlane + planeLength;
                for (NSInteger i = offsetPlane; i < upperLimit; i++) {
                    if(maskIds[i] > 0){
                        NSInteger cellId = maskIds[i] - 1;
                        NSArray *collectedVoxelIndexes = [self collectVoxelsForVoxelIndex:i width:self.width planeLength:planeLength totalMask:fullMask];
    
                        NSMutableArray *positionsX = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                        NSMutableArray *positionsY = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                        NSMutableArray *positionsZ = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                        
                        NSMutableSet *neighbors = [NSMutableSet set];
                        
                        for (NSNumber *num in collectedVoxelIndexes) {
                            NSInteger index = num.integerValue%planeLength;
                            NSInteger planeItBelongs = num.integerValue/planeLength;
                            
                            [positionsX addObject:@(index%maxWidth)];
                            [positionsY addObject:@(index/maxWidth)];
                            [positionsZ addObject:@(planeItBelongs)];
                            
                            for (NSInteger c = 0; c < channelsExtraction; c ++)
                                self.computedData[c][cellId] += (float)auxiliaryData[planeItBelongs][c][index];
                            
                            NSInteger tests[6] = {
                                index + planeLength,
                                index - planeLength,
                                index + maxWidth,
                                index - maxWidth,
                                index + 1,
                                index - 1
                            };
                            for (int j = 0; j < 6; j++) {
                                NSInteger test = tests[j];
                                if(test < fullMask && test >= 0)
                                    if(maskIds[test] != 0 && maskIds[test] != maskIds[i])
                                       [neighbors addObject:@(abs(maskIds[test]))];
                            }
                        }
                        for (NSInteger c = 0; c < channelsExtraction; c ++)
                            self.computedData[c][cellId] /= (float)collectedVoxelIndexes.count;
                        self.computedData[channelsExtraction + 0][cellId] = [positionsX mean].floatValue;
                        self.computedData[channelsExtraction + 1][cellId] = [positionsY mean].floatValue;
                        self.computedData[channelsExtraction + 2][cellId] = [positionsZ mean].floatValue;
                        self.computedData[channelsExtraction + 3][cellId] = neighbors.count;
                        self.computedData[channelsExtraction + 4][cellId] = (float)collectedVoxelIndexes.count;
                    }
                }
            }
            
            //Close remaining slices
            for (NSInteger s = 0; s < self.slices; s++) {
                if(auxiliaryData[s]){
                    for (NSInteger c = 0; c < channelsExtraction; c++)
                        if(auxiliaryData[s][c])
                            free(auxiliaryData[s][c]);
                    free(auxiliaryData[s]);
                }
            }
            if(auxiliaryData)
                free(auxiliaryData);
            
            //Return mask to initial state
            for (NSInteger i = 0; i < fullMask; i++)
                if(maskIds[i] < 0)
                    maskIds[i] = -maskIds[i];
            
            [self saveData];
        });
    }];
}

-(void)passToHandlerChannels:(NSIndexSet *)channels{

    if(channels.count == 0)
    {
        [self passToHandler];
        return;
    }

//    NSMutableIndexSet *removed = [NSMutableIndexSet indexSet];
//    [channels enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
//        if(![lastIndexSet containsIndex:index])
//            [removed addIndex:index];
//    }];
//    
//    NSMutableIndexSet *indexesNew = [NSMutableIndexSet indexSet];
//    [lastIndexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
//        if(![channels containsIndex:index])
//            [indexesNew addIndex:index];
//    }];
    
    if(maskIds){
        NSInteger planeLength = self.width * self.height;
        NSInteger fullMaskLength = planeLength * self.slices;
        
        self.threeDHandler.interestProportions = NSRectFromString(self.roiMask);
        [self.threeDHandler startBufferForImages:self.threeDHandler.loader.inOrderImageWrappers channels:self.channels.count width:self.width height:self.height];
        
        if(self.threeDHandler.allBuffer && self.computedData){
            UInt8 *** allBuff = self.threeDHandler.allBuffer;
            NSInteger slices = self.slices;
            
            
            NSMutableArray *indexesO = @[].mutableCopy;
            NSMutableArray *maxesO = @[].mutableCopy;
            NSInteger numberOfChannels = channels.count;
            NSInteger numberOfSegments = self.segments;
            [channels enumerateIndexesUsingBlock:^(NSUInteger channel, BOOL *stop){
                //Allocate buffers if necessary
                for (NSInteger i = 0; i < slices; i++)
                    if(!allBuff[i][channel])
                        allBuff[i][channel] = calloc(planeLength, sizeof(UInt8));
                
                //Get real channel index
                [indexesO addObject:@(channel)];
                
                //Find maximum value
                int localMax = 0;
                for(NSInteger i = 0; i < numberOfSegments; i++)
                    localMax = MAX(localMax, self.computedData[channel][i]);
                
                //Keep Max value
                [maxesO addObject:@(localMax)];
            }];
            
            
            //Make C indexes ad Maxes for speed
            NSInteger indexes[numberOfChannels];
            NSInteger maxes[numberOfChannels];
            for (int i = 0; i < numberOfChannels; i++){
                indexes[i] = [indexesO[i]integerValue];
                maxes[i] = [maxesO[i]integerValue];
                NSLog(@"Max %li ", maxes[i]);
            }
            
            UInt8 ** proc = calloc(numberOfChannels, sizeof(UInt8 *));
            for (int c = 0; c < numberOfChannels; c++)
                proc[c] = calloc(numberOfSegments, sizeof(UInt8));
            for (int c = 0; c < numberOfChannels; c++)
                for (int s = 0; s < numberOfSegments; s++)
                    proc[c][s] = (UInt8)self.computedData[indexes[c]][s] * 255.0f / maxes[c];
            
            for (NSInteger i = 0; i < fullMaskLength; i++) {
                if(maskIds[i] > 0){
                    NSInteger plane = i / planeLength;
                    NSInteger pix = i % planeLength;
                    NSInteger cell = maskIds[i] - 1;
                    
                    for (int chan = 0; chan < numberOfChannels; chan++)
                        allBuff[plane][indexes[chan]][pix] = proc[chan][cell];//(UInt8)(computedData[indexes[chan]][cell] * 255.0f / maxes[chan]);

                }
            }
            for (int c = 0; c < numberOfChannels; c++)
                free(proc[c]);
            free(proc);

        }
        [self.threeDHandler meanBlurModelWithKernel:3 forChannels:channels mode:self.blurMode];
    }
}

//Overriden because the number of cells don't come from mask parent but from the class directly
-(NSMutableArray *)arrayNumbersForIndex:(NSInteger)index{
    NSMutableArray *array = @[].mutableCopy;
    NSInteger cells = self.segmentedUnits;
    float *data = self.computedData[index];
    for (int i = 0; i < cells; i++) {
        float val = data[i];
        if(val > 0){
            [array addObject:[NSNumber numberWithFloat:val]];
        }
    }
    return array;
}

-(void)poligonizeMask{
    if(maskIds){
        NSInteger width = self.width + 1;
        NSInteger height = self.height + 1;
        NSInteger slices = self.slices + 1;
        
        
        for (int s = 0; s < slices; s++) {
            for(int i = 0; i < width; i++){
                for (int j = 0; j < height; j++) {
                    
                    //NSInteger touchingIds[8] = {};//A, B, C, D, E, F, G, H
                }
            }
        }
    }
}

-(void)interactionAnalysis:(NSInteger)clusteringChannel{
    if(maskIds){
        NSInteger width = self.width;
        NSInteger planeLength = self.width * self.height;
        NSInteger fullMaskLength = planeLength * self.slices;
        
        
        //Generate adacency matrix
        NSMutableDictionary *dict = @{}.mutableCopy;
        for (NSInteger i = 0; i < fullMaskLength; i++) {
            if(maskIds[i] > 0){
                NSArray *collectedVoxelIndexes = [self collectVoxelsForVoxelIndex:i width:self.width planeLength:planeLength totalMask:fullMaskLength];
                
                NSMutableSet *neighbors = [NSMutableSet set];
                for (NSNumber *num in collectedVoxelIndexes) {
                    NSInteger index = num.integerValue % planeLength;
                    
                    NSInteger tests[6] = {
                        index + planeLength,
                        index - planeLength,
                        index + width,
                        index - width,
                        index + 1,
                        index - 1
                    };
                    for (int j = 0; j < 6; j++) {
                        NSInteger test = tests[j];
                        if(test < fullMaskLength && test >= 0)
                            if(maskIds[test] != 0 && maskIds[test] != maskIds[i])
                                [neighbors addObject:@(abs(maskIds[test]))];
                    }
                }
                [dict setValue:neighbors forKey:[NSString stringWithFormat:@"%i", -maskIds[i]]];
            }
        }
        
        //Return mask to initial state
        for (NSInteger i = 0; i < fullMaskLength; i++)
            if(maskIds[i] < 0)
                maskIds[i] = -maskIds[i];
        
        //Get channel with clusters
        float * clusters = self.computedData[clusteringChannel];
        
        //Calculate maximum number of clusters
        NSInteger cells = self.segmentedUnits;
        NSInteger numberOfClusters = 0;
        for (NSInteger i = 0; i < cells; i++)
            if(clusters[i] > numberOfClusters)
                numberOfClusters = (NSInteger)clusters[i];
        
        NSLog(@"We have %li %li", numberOfClusters, clusteringChannel);
        //Get abundances
        NSInteger *abundances = calloc(numberOfClusters, sizeof(NSInteger));
        for (NSInteger i = 0; i < cells; i++)
            abundances[(NSInteger)(clusters[i] - 1)]++;
        
        for (NSInteger i = 0; i < numberOfClusters; i++)
            printf("cluster %li has %li\n", i + 1, abundances[i]);
    }
}

-(void)distanceToOtherMaskBlock:(IMC3DMask *)otherMask{
    if(otherMask.width == self.width && otherMask.height == self.height && otherMask.slices == self.slices){
        [otherMask openIfNecessaryAndPerformBlock:^{
            NSInteger max = self.segmentedUnits;
            
            float *results = calloc(max, sizeof(float));
            bool *visited = calloc(max, sizeof(bool));
            NSInteger *indexes = calloc(max, sizeof(NSInteger));
            
            NSInteger width = self.width;
            NSInteger height = self.height;
            NSInteger slices = self.slices;
            NSInteger plane = width * height;
            NSInteger total = plane * slices;
            
            float * xCentroids = [self xCentroids];
            float * yCentroids = [self yCentroids];
            float * zCentroids = [self zCentroids];
            
            int * maskDestination = otherMask->maskIds;
            NSInteger processed = 0;
            
            //Initial visit (for those that are already in mask)
            for (NSInteger i = 0; i < max; i++) {
                //printf("%f %f %f | ", xCentroids[i], yCentroids[i], zCentroids[i]);
                NSInteger index = round(zCentroids[i]) * plane + round(yCentroids[i]) * width + round(xCentroids[i]);
                if(maskDestination[index] > 0){
                    visited[i] = true;
                    processed++;
                }
                indexes[i] = index;
            }
            
            BOOL found = YES;
            int distance = 1;
            BOOL firstRound = YES;
            
            BOOL oddCycle = NO;
            while (found == YES && processed < max) {
                printf("-");
                //Expand mask
                found = NO;
                for (NSInteger i = 0; i < total; i++) {
                    
                    if((maskDestination[i] > 0 && firstRound) || maskDestination[i] == -1){
                        
                        int voxelsToExpand = oddCycle ? 6 : 4;
                        
                        NSInteger tests[6] = {
                            i + width,
                            i - width,
                            i + 1,
                            i - 1,
                            i + plane,
                            i - plane
                        };
                        for (int j = 0; j < voxelsToExpand; j++) {
                            NSInteger test = tests[j];
                            if(test < total && test >= 0){
                                if(maskDestination[test] == 0){
                                    maskDestination[test] = -2;
                                    found = YES;
                                }
                            }
                        }
                    }
                }
                firstRound = NO;
                
                //Find if new centroid in expanded area
                for (NSInteger i = 0; i < max; i++) {
                    if(visited[i] == false){
                        NSInteger index = indexes[i];
                        if(maskDestination[index] == -2){
                            visited[i] = true;
                            results[i] = distance;
                            processed++;
                        }
                    }
                }
                
                //Turn candidates into inactive
                for (NSInteger i = 0; i < total; i++) {
                    if(maskDestination[i] == -1)
                        maskDestination[i] = -3;//Archived
                    if(maskDestination[i] == -2)//Used in this round
                        maskDestination[i] = -1;//Will be ref for expansion in next round
                }
                oddCycle = !oddCycle;
                distance++;
            }
            
            //Clean up and restore mask state
            for (NSInteger i = 0; i < total; i++) {
                if(maskDestination[i] < 0)
                    maskDestination[i] = 0;
            }
            free(visited);
            free(indexes);
            
            [self addBuffer:results withName:[NSString stringWithFormat:@"Distance to %@", otherMask.itemName] atIndex:NSNotFound];
        }];
    }
}


-(void)distanceToOtherMaskEuclidean:(IMC3DMask *)otherMask{
    if(otherMask.width == self.width && otherMask.height == self.height && otherMask.slices == self.slices){
        [otherMask openIfNecessaryAndPerformBlock:^{
            NSInteger max = self.segmentedUnits;
            
            float *results = calloc(max, sizeof(float));
            for(NSInteger c = 0; c < max; c++)
                results[c] = CGFLOAT_MAX;
            bool *visited = calloc(max, sizeof(bool));
            
            NSInteger width = self.width;
            NSInteger height = self.height;
            NSInteger slices = self.slices;
            NSInteger plane = width * height;
            NSInteger total = plane * slices;
            
            float * xCentroids = [self xCentroids];
            float * yCentroids = [self yCentroids];
            float * zCentroids = [self zCentroids];
            
            int * maskDestination = otherMask->maskIds;
            
            //Initial visit (for those that are already in mask)
            for (NSInteger i = 0; i < max; i++) {
                NSInteger index = round(zCentroids[i]) * plane + round(yCentroids[i]) * width + round(xCentroids[i]);
                if(maskDestination[index] > 0){
                    visited[i] = true;
                    results[i] = .0f;
                }
            }
            
            NSMutableArray *edges = @[].mutableCopy;
            //Remove non edges
            for (NSInteger i = 0; i < total; i++) {
                if(maskDestination[i] > 0){
                    NSInteger tests[6] = {
                        i + 1,
                        i - 1,
                        i + width,
                        i - width,
                        i + plane,
                        i - plane
                    };
                    BOOL isEdge = NO;
                    for (int j = 0; j < 6; j++) {
                        NSInteger test = tests[j];
                        if(test >= 0 && test < total){
                            if(maskDestination[test] == 0){
                                isEdge = YES;
                                break;
                            }
                        }
                    }
                    if(isEdge)
                        [edges addObject:@(i)];
                }
            }
            
            NSLog(@"Edges %li", edges.count);
            for (NSNumber *index in edges) {
                NSInteger cIndex = index.integerValue;
                NSInteger xEdge = cIndex%width;
                NSInteger yEdge = (cIndex%plane)/width;
                NSInteger zEdge = cIndex/plane;
                for (NSInteger c = 0; c < max; c++) {
                    if(visited[c] == false){
                        float difX = xCentroids[c] - xEdge;
                        float difY = yCentroids[c] - yEdge;
                        float difZ = zCentroids[c] - zEdge;
                        float dist = difX * difX + difY * difY + difZ * difZ * 4;//Hardcoded for 2 micron
                        if(dist < results[c])
                            results[c] = dist;//
                    }
                }
            }
            NSLog(@"Done");
            //Do expensive square roots
            for (NSInteger i = 0; i < max; i++) {
                if(results[i] > 0)
                    results[i] = sqrtf(results[i]);
            }
            NSLog(@"Finished");
            free(visited);
            
            [self addBuffer:results withName:[NSString stringWithFormat:@"Distance to %@", otherMask.itemName] atIndex:NSNotFound];
        }];
    }
}

-(void)dealloc{
    [self clearComputedData];
    [self releaseMask];
}

@end
