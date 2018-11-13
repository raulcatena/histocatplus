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

//@interface IMC3DMask(){
    UInt8 *** auxiliaryData;
    NSIndexSet *lastIndexSet;
//}

//@end

@implementation IMC3DMask

-(instancetype)initWithLoader:(IMCLoader *)loader andHandler:(IMC3DHandler *)handler{
    self = [self init];
    if(self){
        self.coordinator = loader;
        self.threeDHandler = handler;
    }
    return self;
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
-(NSString *)itemName{
    return self.jsonDictionary[JSON_DICT_ITEM_NAME];
}
-(NSString *)itemSubName{
    NSString *pre = self.origin == MASK3D_VOXELS ? @"Voxel-based_" : @"Mask-based_";
    return [pre stringByAppendingString:self.itemHash];
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
-(NSMutableArray *)channelsWS{
    return self.metadata[JSON_DICT_3DS_METADATA_CHANNELS_WS];
}
-(void)setChannelsWS:(NSArray *)channelsWS{
    self.metadata[JSON_DICT_3DS_METADATA_CHANNELS_WS] = channelsWS.mutableCopy;
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
                if(_maskIds[test] > 0){
                    NSNumber *keyNum = @(_maskIds[test]);
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
                if(_maskIds[test] == 0)
                    return YES;
            if(test < 0 || test >= fullMaskLength)
                return YES;
        }
    }
    return NO;
}

-(void)assignIdOld:(int)cellId toIndex:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
    _maskIds[testIndex] = cellId;
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
                            if (_maskIds[index] == -1) {
                                if([self touchesId:index fullMaskLength:fullMaskLength planLength:plane] != cellId){
                                    _maskIds[index] = cellId;
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
    
    _maskIds[testIndex] = cellId;
    
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
                if(_maskIds[candidates[m]] == -1){
                    _maskIds[candidates[m]] = cellId;
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
                    if(_maskIds[test] == -1 && testIndex != test){
                        _maskIds[test] = cellId;
                        [self recurseGiveId:test fullMaskLength:fullMaskLength planLength:plane cellId:cellId width:width];
                    }
            }
        }
    }
    _maskIds[testIndex] = cellId;
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
                            if (_maskIds[index] == -1) {
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
                if(_maskIds[candidates[m]] == -1){
                    _maskIds[candidates[m]] = -2;
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
            _maskIds[num.integerValue] = -1;
    
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
                    if(_maskIds[test] == -1 && testIndex != test){
                        _maskIds[test] = 0;
                        return 1 + [self recursiveCheckCandidates:test fullMaskLength:fullMaskLength planLength:plane width:width];
                    }
            }
        }
    }
    return 0;
}

-(void)resetNegs:(NSInteger)allLength{
    for (NSInteger i = 0; i < allLength; i++)
        if(_maskIds[i] < 0)
            _maskIds[i] = 0;
}
-(void)invertNegs:(NSInteger)allLength{
    for (NSInteger i = 0; i < allLength; i++)
        if(_maskIds[i] < 0)
            _maskIds[i] = -_maskIds[i];
}

-(void)extractMaskFromRender{
    
    IMC3DHandler *handler = self.threeDHandler;
    
    self.width = handler.width;
    self.height = handler.height;
    self.slices = handler.images;
    
    self.roiMask = NSStringFromRect(self.threeDHandler.interestProportions);
    
    NSInteger planeLength = self.width * self.height;
    NSInteger fullMask = planeLength *  self.slices;
    NSInteger channel = self.channel;
    NSArray *channels = self.channelsWS;
    int cChannels[channels.count];
    int counter = 0;
    for (NSNumber *num in channels) {
        cChannels[counter] = num.intValue;
        counter++;
    }
    NSInteger schannel = self.substractChannel;
    
    float final = self.threshold;

    [self releaseMask];
    
    _maskIds = calloc(fullMask, sizeof(int));
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
                NSInteger offset = planeLength * i;
                if(handler.allBuffer[i]){
                    for (NSInteger j = 0; j < planeLength; j++){
                        if(mask[j] == false)
                            continue;
                        if (_maskIds[offset + j] == -1){
                            int neigh = [self touchesId:offset + j fullMaskLength:fullMask planLength:planeLength];
                            if(neigh > 0)
                                _maskIds[offset + j] = neigh;
                        }
                        if (_maskIds[offset + j] == 0){
                            float val = 0;
                            for(NSInteger c = 0; c < channels.count; c++)
                                if(handler.allBuffer[i][cChannels[c]])
                                    val += handler.allBuffer[i][cChannels[c]][j];
                            
                            if(schannel != NSNotFound)
                                if(handler.allBuffer[i][schannel])
                                    val -= handler.allBuffer[i][schannel][j]/2;//2 is heuristic
                            
                            val = MIN(255, val);
                            if(val >= analyzeAdded){
                                _maskIds[offset + j] = [self touchesId:offset + j fullMaskLength:fullMask planLength:planeLength];
                            }
                        }
                    }
                }
            }
            for (NSInteger i = 0; i < handler.images; i++) {
                NSInteger offset = planeLength * i;
                if(handler.allBuffer[i]){
                    for (NSInteger j = 0; j < planeLength; j++){
                        if(mask[j] == false)
                            continue;
                        if (_maskIds[offset + j] == -1){
                            int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:planeLength width:self.width once:NO];
                            if(qual >= self.minKernel){//Promote all
                                [self assignId:cellId toIndex:offset + j fullMaskLength:fullMask planLength:planeLength width:self.width];
                                cellId++;
                            }
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
            NSInteger offset = planeLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < planeLength; j++){
                        if(mask[j] == false)
                            continue;
                        if (_maskIds[offset + j] == 0){
                            float val = (float)handler.allBuffer[i][channel][j];
                            if(schannel != NSNotFound && handler.allBuffer[i][schannel])
                                val -= handler.allBuffer[i][schannel][j];
                            if(val >= analyze)
                                _maskIds[offset + j] = -1;
                        }
                    }
        }
        int cellId = 1;
        for (NSInteger i = 0; i < handler.images; i++) {
            NSInteger offset = planeLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < planeLength; j++){
                        if(mask[j] == false)
                            continue;
                        if (_maskIds[offset + j] == -1){
                            int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:planeLength width:self.width once:NO];
                            if(qual >= self.minKernel){//Promote all
                                [self assignId:self.type == MASK3D_THRESHOLD_SEGMENT?cellId:1 toIndex:offset + j fullMaskLength:fullMask planLength:planeLength width:self.width];
                                NSLog(@"ID %i", cellId);
                                cellId++;
                            }
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
    
    //Save file with mask
    [self saveMaskData];
    
    //Prepare the 3D buffer handler
    [self passToHandler];
    
    //Load up node
    self.isLoaded = YES;
}

-(void)expand{
    
    IMC3DHandler *handler = self.threeDHandler;
    
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  handler.images;
    NSInteger width = self.width;
    
    for (NSInteger i = 0; i < self.expansion; i++) {
        
        NSInteger zpass = i % 2 == 0 ? fullMask : allLength;
        
        for (NSInteger j = 0; j < fullMask; j++) {

            int val = _maskIds[j];
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
                        if (_maskIds[candidates[m]] == 0)
                            _maskIds[candidates[m]] = -val;
            }
        }
        [self invertNegs:fullMask];
    }
    
}

-(void)removeBordersForMask{
    NSInteger allLength = self.width * self.height;
    NSInteger fullMaskLength = allLength * self.slices;
    for(NSInteger i = 0; i < fullMaskLength; i++){
        if(_maskIds[i] > 0){
            NSInteger indexes[6] = {i + 1, i -1, i + self.width, i - self.width, i + allLength, i - allLength};
            
            //Older implementation less aggresive border removal and slower
//            NSMutableSet * found = [NSMutableSet setWithObject:@(abs(_maskIds[i]))];
//            for (int j = 0; j < 6; j++) {
//                if(indexes[j] >= 0 && indexes[j] < fullMaskLength)
//                    [found addObject:@(abs(_maskIds[indexes[j]]))];
//            }
//            if(found.count > 1)
//                _maskIds[i] = -_maskIds[i];
            
            //Newer implementation more aggresive border removal and faster
            for (int j = 0; j < 6; j++) {
                if(indexes[j] >= 0 && indexes[j] < fullMaskLength)
                    if(abs(_maskIds[indexes[j]]) != abs(_maskIds[i])){
                        _maskIds[i] = -_maskIds[i];
                        break;
                    }
            }
        }
    }
}
-(void)restoreBordersToMask{
    NSInteger allLength = self.width * self.height;
    NSInteger fullMaskLength = allLength * self.slices;
    for(NSInteger i = 0; i < fullMaskLength; i++)
        if(_maskIds[i] < 0)
            _maskIds[i] = -_maskIds[i];
}

-(void)passToHandler{
    if (_maskIds){
        
        if(self.noBorders)
            [self removeBordersForMask];
        
        NSInteger allLength = self.width * self.height;
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
                        int maskId = _maskIds[offSet + j];
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
    if (_maskIds){
        NSLog(@"Releasing mask 3D Memory");
        free (_maskIds);
        _maskIds = NULL;
    }
}
-(void)releaseVerts{
    if (_verts){
        NSLog(@"Releasing vertex 3D Memory");
        free (_verts);
        _verts = NULL;
    }
    if (_cellTriangleOffsets){
        NSLog(@"Releasing cell triangle offsets");
        free (_cellTriangleOffsets);
        _cellTriangleOffsets = NULL;
    }
    _numberOfTriangleVertices = 0;
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
    if (_maskIds){
        NSInteger elems = self.slices * self.width * self.height;
        NSInteger count = elems * sizeof(int);
        int * compMask = malloc(count);
        
        int cursorComp = 0;
        int scopeValue = _maskIds[0], inRow = 1;
        for (NSInteger i = 1; i < elems; i++) {
            if (_maskIds[i] == scopeValue)
                inRow++;
            else{
                compMask[cursorComp] = inRow;
                compMask[cursorComp + 1] = scopeValue;
                cursorComp += 2;
                inRow = 1;
                scopeValue = _maskIds[i];
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
    
    for (NSInteger i = 0; i < channels; i++){
        NSLog(@"%li", i);
        if(self.computedData[i])
            [data appendBytes:self.computedData[i] length:self.segmentedUnits * sizeof(float)];
    }
    
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
-(void)loadLayerDataWithBlock:(void (^)(void))block{
    
    if(![self canLoad])return;
    
    NSString *path = [self pathFile];
    NSData *data = [NSData dataWithContentsOfFile:path];
    
    if(data){
        [self releaseMask];
        NSInteger elems = self.slices * self.width * self.height;
        NSInteger count = elems * sizeof(int);
        _maskIds = malloc(count);
        
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
                _maskIds[counter] = val;
                counter++;
            }
        }
    }
    [self passToHandler];
    
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
    self.isLoaded = YES;
    
    [self poligonizeFieldWithMarchingCubes];
    
}
-(void)unLoadLayerDataWithBlock:(void (^)(void))block{
    [self releaseMask];
    [self clearComputedData];
    [super unLoadLayerDataWithBlock:block];
}

#pragma mark extract cell data

-(NSInteger)depthFromVoxel:(NSInteger)voxelIndex width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger cellId = _maskIds[voxelIndex];
    _maskIds[voxelIndex] = -_maskIds[voxelIndex];
    
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
//        NSInteger candidates[6] = {val - width,
//        NSInteger newerBase = val + planeLength;
//        NSInteger candidates[9] = {newerBase,
//            newerBase - 1,
//            newerBase + 1,
//            newerBase - width,
//            newerBase - width - 1,
//            newerBase - width + 1,
//            newerBase + width,
//            newerBase + width - 1,
//            newerBase + width + 1,
//        };
//        
//        for (int m = 0; m < 9;  m++){
        for (int m = 0; m < 6;  m++){
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if (_maskIds[candidates[m]] == cellId){
                    _maskIds[candidates[m]] = -_maskIds[candidates[m]];
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
        _maskIds[vox] = -_maskIds[vox];
    }
    return maxDepth;
}

-(NSInteger)maxDepthInPlane:(NSInteger)plane width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger planeOffset = planeLength * plane;
    
    NSInteger maxDepth = 0;
    NSMutableArray *seen = @[].mutableCopy;
    for (NSInteger i = 0; i < planeLength; i++) {
        NSInteger index = planeOffset + i;
        if (_maskIds[index] > 0){
            if(![seen containsObject:@ (_maskIds[index])]){
                [seen addObject:@ (_maskIds[index])];
                NSInteger depth = [self depthFromVoxel:index width:width planeLength:planeLength totalMask:fullMaskLength];
                maxDepth = MAX(maxDepth, depth);
            }
        }
    }
    return maxDepth;
}

-(NSArray *)collectVoxelsForVoxelIndex:(NSInteger)voxelIndex width:(NSInteger)width planeLength:(NSInteger)planeLength totalMask:(NSInteger)fullMaskLength{
    
    NSInteger cellId = _maskIds[voxelIndex];
    _maskIds[voxelIndex] = -_maskIds[voxelIndex];
    
    NSMutableArray *voxels = @[].mutableCopy;
    NSMutableArray *processing = @[].mutableCopy;
    
    NSNumber * testVoxel = @(voxelIndex);
    
    while (testVoxel) {
        NSInteger val = testVoxel.integerValue;
        
//        NSInteger newerBase = val + planeLength;
//        NSInteger candidates[17] = {
//            val - 1,
//            val + 1,
//            val - width,
//            val - width - 1,
//            val - width + 1,
//            val + width,
//            val + width - 1,
//            val + width + 1,
//            newerBase,
//            newerBase - 1,
//            newerBase + 1,
//            newerBase - width,
//            newerBase - width - 1,
//            newerBase - width + 1,
//            newerBase + width,
//            newerBase + width - 1,
//            newerBase + width + 1,
//        };
        
        NSInteger candidates[6] = {val - width,
            val + width,
            val - 1,
            val + 1,
            val - planeLength,
            val + planeLength
        };
        //for (int m = 0; m < 17;  m++){
        for (int m = 0; m < 6;  m++){
        
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if (_maskIds[candidates[m]] == cellId){
                    _maskIds[candidates[m]] = -_maskIds[candidates[m]];
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
-(void)copyThisMask{
    IMC3DMask *newMask = [[IMC3DMask alloc]init];
    newMask.jsonDictionary = self.jsonDictionary.copy;
    newMask.itemHash = [IMCUtils randomStringOfLength:20];
    newMask.itemName = [@"copy of " stringByAppendingString:newMask.itemName];
    NSInteger elems = self.slices * self.width * self.height;
    NSInteger count = elems * sizeof(int);
    newMask.maskIds = malloc(count);
    [self openIfNecessaryAndPerformBlock:^{
        for (NSInteger i = 0; i < count; i++)
            newMask.maskIds[i] = self.maskIds[i];
        [newMask saveMaskData];
    }];
    [self.coordinator add3DNode:newMask];
}

-(void)allocateComputedData{
    
    [self clearComputedData];
    
    NSInteger channels = [[self channels]count];
    self.computedData = malloc(channels * sizeof(float *));
    for (NSInteger c = 0; c < channels; c++)
        self.computedData[c] = calloc(self.segments, sizeof(float));
}

-(void)loadSlice:(IMCImageStack *)stack toBuffer:(UInt8 **)auxBuffer canvasW:(NSInteger)maxWidth canvasH:(NSInteger)maxHeight channels:(NSInteger)channelsExtraction planeLength:(NSInteger)planeLength{
    
    //Alternative way
//    NSMutableArray *allChannels = @[].mutableCopy;
//    for (int z = 0; z < stack.channels.count; z++)
//        [allChannels addObject:@(z)];
//    
//    NSInteger pixels = stack.numberOfPixels;
//    NSInteger * mapIndexes = [stack mapOfIndexesAfterAffineWithSuperCanvasW:maxWidth superCanvasH:maxHeight];
//
//    NSLog(@"Generate Images");
//    UInt8 ** buffs = [stack preparePassBuffers:allChannels];
//    
//    NSLog(@"Start Transfer");
//    for (NSInteger c = 0; c < channelsExtraction; c++) {
//        UInt8 *buf = buffs[c];
//        for(NSInteger pix = 0; pix < planeLength; pix++)
//            if(mapIndexes[pix] >= 0 && mapIndexes[pix] < pixels)
//                auxBuffer[c][pix] += buf[mapIndexes[pix]];
//    }
//    free(mapIndexes);

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
    
    //[self openIfNecessaryAndPerformBlock:^{
    NSInteger option = [IMCUtils inputOptions:@[@"Full mask", @"Exclude borders"] prompt:@"Choose an option"];
    if(option == NSNotFound)
        return;
    if(option == 1 && self.noBorders == NO){
        [self removeBordersForMask];
    }
    else if(option == 0)
    {
        [self restoreBordersToMask];
    }
    
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
            if (_maskIds[i] > total)
                total = _maskIds[i];
        
        if(total > 0)
            self.segments = total - 1;
        else
            return;
    }

    [self allocateComputedData];
    auxiliaryData = calloc(self.slices, sizeof(UInt8 **));
    NSLog(@"Segments %li ", self.segments);
    
    dispatch_queue_t slicer = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(slicer, ^{
        
        NSInteger end = 0;
        for (NSInteger p = 0; p < self.slices; p++) {
            //Find until where deepest voxel falls
            NSInteger lastTouchedPlane = [self maxDepthInPlane:p width:self.width planeLength:planeLength totalMask:fullMask];
            
            //In case stuff has been removed, avoid going off bounds
            while(lastTouchedPlane >= self.threeDHandler.indexesArranged.count)
                lastTouchedPlane--;
            
            //Define range to have open only relevant slices
            NSInteger begg = [self.threeDHandler internalSliceIndexForExternal:p];
            end = MAX(end, [self.threeDHandler internalSliceIndexForExternal:lastTouchedPlane]);
            
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
                if (self->_maskIds[i] > 0){
                    NSInteger cellId = self->_maskIds[i] - 1;
                    NSArray *collectedVoxelIndexes = [self collectVoxelsForVoxelIndex:i width:self.width planeLength:planeLength totalMask:fullMask];
                    
                    if(collectedVoxelIndexes.count < 20)//RCF heuristic May pass as parameter
                        continue;

                    NSMutableArray *positionsX = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                    NSMutableArray *positionsY = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                    NSMutableArray *positionsZ = [NSMutableArray arrayWithCapacity:collectedVoxelIndexes.count];
                    
                    NSMutableSet *neighbors = [NSMutableSet set];
                    
                    for (NSNumber *num in collectedVoxelIndexes) {
                        
                        NSInteger index = num.integerValue%planeLength;
                        NSInteger planeItBelongs = num.integerValue/planeLength;
                        if(planeItBelongs > lastTouchedPlane)
                            continue;
                        
                        [positionsX addObject:@(index%maxWidth)];
                        [positionsY addObject:@(index/maxWidth)];
                        [positionsZ addObject:@(planeItBelongs)];

                        for (NSInteger c = 0; c < channelsExtraction; c++)
                            self.computedData[c][cellId]  += (float)auxiliaryData[planeItBelongs][c][index];
                        
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
                                if (self->_maskIds[test] != 0 && self->_maskIds[test] != self->_maskIds[i])
                                   [neighbors addObject:@(abs (self->_maskIds[test]))];
                        }
                    }
                    for (NSInteger c = 0; c < channelsExtraction; c++)
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
        [self invertNegs:fullMask];

        //for (NSInteger i = 0; i < fullMask; i++)
        //    if (_maskIds[i] < 0)
        //        _maskIds[i] = -_maskIds[i];
        
        [self saveData];
    });
    //}];
}

#pragma mark pass to handler

-(void)passToHandlerChannels:(NSIndexSet *)channels{

    if(channels.count == 0)
    {
        [self passToHandler];
        lastIndexSet = nil;
        return;
    }
    
    if([channels isEqualToIndexSet:lastIndexSet])
        return;
    
    NSMutableIndexSet *toDoChannels = [NSMutableIndexSet indexSet];
    [channels enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        if(![lastIndexSet containsIndex:index])
            [toDoChannels addIndex:index];
    }];
    
    if (_maskIds){
        
        NSInteger planeLength = self.width * self.height;
        NSInteger fullMaskLength = planeLength * self.slices;
        
        self.threeDHandler.interestProportions = NSRectFromString(self.roiMask);
        if(self.threeDHandler.channels != self.channels.count || self.threeDHandler.images != self.slices || !lastIndexSet){
            [self.threeDHandler startBufferForImages:self.threeDHandler.loader.inOrderImageWrappers channels:self.channels.count width:self.width height:self.height];
            toDoChannels = channels.mutableCopy;
        }
        
        if(self.threeDHandler.allBuffer && self.computedData){
            UInt8 *** allBuff = self.threeDHandler.allBuffer;
            NSInteger slices = self.slices;
            if(slices >= self.threeDHandler.indexesArranged.count)
                slices = self.threeDHandler.indexesArranged.count - 1;
            
            
            NSMutableArray *indexesO = @[].mutableCopy;
            NSMutableArray *maxesO = @[].mutableCopy;
            NSInteger numberOfChannels = toDoChannels.count;
            NSInteger numberOfSegments = self.segments;
            [toDoChannels enumerateIndexesUsingBlock:^(NSUInteger channel, BOOL *stop){
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
                    proc[c][s] = (UInt8)(self.computedData[indexes[c]][s] * 255.0f / maxes[c]);
            
        
            for (NSInteger i = 0; i < fullMaskLength; i++) {
                if (_maskIds[i] > 0){
                    NSInteger plane = i / planeLength;
                    if(plane >= slices)continue;
                    NSInteger pix = i % planeLength;
                    NSInteger cell = _maskIds[i] - 1;
                    
                    for (int chan = 0; chan < numberOfChannels; chan++)
                        allBuff[plane][indexes[chan]][pix] = proc[chan][cell];
                }
            }
            for (int c = 0; c < numberOfChannels; c++)
                free(proc[c]);
            free(proc);

            [self.threeDHandler meanBlurModelWithKernel:3 forChannels:toDoChannels mode:self.blurMode];
        }
    }
    lastIndexSet = channels;
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

-(void)interactionAnalysis:(NSInteger)clusteringChannel{
    if (_maskIds){
        NSInteger width = self.width;
        NSInteger planeLength = self.width * self.height;
        NSInteger fullMaskLength = planeLength * self.slices;
        
        
        //Generate adacency matrix
        NSMutableDictionary *dict = @{}.mutableCopy;
        for (NSInteger i = 0; i < fullMaskLength; i++) {
            if (_maskIds[i] > 0){
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
                            if (_maskIds[test] != 0 && _maskIds[test] != _maskIds[i])
                                [neighbors addObject:@(abs (_maskIds[test]))];
                    }
                }
                [dict setValue:neighbors forKey:[NSString stringWithFormat:@"%i", -_maskIds[i]]];
            }
        }
        
        //Return mask to initial state
        for (NSInteger i = 0; i < fullMaskLength; i++)
            if (_maskIds[i] < 0)
                _maskIds[i] = -_maskIds[i];
        
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
            
            int * maskDestination = otherMask->_maskIds;
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
                            if(doesNotJumpLinePlane(i, test, width, height, plane, total, 2)){
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
    NSLog(@"%li %li %li %li %li", otherMask.width, self.width, otherMask.height, otherMask.slices, self.slices);
    if(otherMask.width == self.width && otherMask.height == self.height && otherMask.slices >= self.slices){
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
            
            int * maskDestination = otherMask->_maskIds;
            
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
                        if(doesNotJumpLinePlane(i, test, width, height, plane, total, 2)){
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
            int l = 0;
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
                if(l % 1000 == 0)printf(".");
                l++;
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

#pragma mark
-(NSArray *)touchedIds:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane{
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
                if(_maskIds[test] != 0 && abs(_maskIds[test]) != abs(_maskIds[testIndex])){
                    NSNumber *keyNum = @(abs(_maskIds[test]));
                    dic[keyNum] = dic[keyNum]?@([dic[keyNum]integerValue]+1):@(1);
                }
        }
    }
    return dic.allKeys;
}
-(NSArray *)generateAdjacencyMatrix{
    NSInteger planeLength = self.width * self.height;
    NSInteger fullMask = planeLength *  self.slices;
    [self invertNegs:fullMask];
    NSInteger total = self.segments;
    NSMutableArray *adjMatrix = @[].mutableCopy;
    for (NSInteger i = 0; i < total; i++)
        [adjMatrix addObject:@[].mutableCopy];
    
    int processed = 0;
    for (NSInteger i = 0; i < fullMask; i++) {
        if(_maskIds[i] > 0){
            int index = _maskIds[i];
            processed++;
            if(processed > total/100){
                processed = 0;
                printf(".");
            }
            NSArray *collectedVoxelIndexes = [self collectVoxelsForVoxelIndex:i width:self.width planeLength:planeLength totalMask:fullMask];
            for (NSNumber *num in collectedVoxelIndexes) {
                NSArray *touched = [self touchedIds:abs(num.intValue) fullMaskLength:fullMask planLength:planeLength];
                for (NSNumber *anId in touched) {
                    NSNumber *interactee = @(abs(anId.intValue));
                    if(![adjMatrix[index - 1] containsObject:interactee])
                        [adjMatrix[index - 1] addObject:interactee];
                }
            }
        }
    }
    [self invertNegs:fullMask];
    
    return adjMatrix;
}
-(NSInteger)maxCategorical:(NSInteger)indexOfCategoricalVariable{
    if(indexOfCategoricalVariable == NSNotFound)
        return 0;
    
    NSInteger total = self.segments;
    NSInteger maxCluster = 0;
    for (NSInteger i = 0; i < total; i++) {
        float val = self.computedData[indexOfCategoricalVariable][i];
        if(roundf(val) != val){
            [General runAlertModalWithMessage:@"Not a categorical variable"];
            return 0;
        }
        if((NSInteger)val > maxCluster)
            maxCluster = (NSInteger)val;
    }
    return maxCluster;
}
-(float *)summaryOfAdjacencyMatrixUsingCategoricalVariable:(NSInteger)indexOfCategoricalVariable forAdjacencyMatrix:(NSArray *)matrix{
    
    NSInteger total = self.segments;
    
    NSInteger maxCluster = [self maxCategorical:indexOfCategoricalVariable];
    
    if(!matrix || maxCluster <= 0)
        return NULL;
    
    if(maxCluster == 0)
        return NULL;
    
    //Generate summary
    float *summary = calloc(maxCluster * 3, sizeof(float));
    for (NSInteger i = 0; i < total; i++) {
        NSInteger clust = (NSInteger)self.computedData[indexOfCategoricalVariable][i];
        summary[(clust - 1) * 3] += [matrix[i]count];
        summary[(clust - 1) * 3 + 1] += 1.0f;
    }
    //Report results
    printf("\n");
    for (NSInteger i = 0; i < maxCluster; i++) {
        if(summary[i * 3 + 1] > 0)
            summary[i * 3 + 2] = summary[i * 3]/summary[i * 3 + 1];
        printf("cluster %li has %li neighbors and %li members. Average neighbors are %f\n", i + 1, (NSInteger)summary[i * 3], (NSInteger)summary[i * 3 + 1], summary[i * 3 + 2]);
    }
    
    return summary;
}
-(float *)expectedMatrixWithSummary:(float *)summary forAdjacencyMatrix:(NSArray *)matrix categoricalVariable:(NSInteger)indexOfCategoricalVariable{

    NSInteger total = self.segments;
    NSLog(@"Total are %li", total);
    NSInteger maxCluster = [self maxCategorical:indexOfCategoricalVariable];
    
    if(summary == NULL || maxCluster <= 0)
        return NULL;
    
    float *expectedMatrix = calloc(maxCluster * maxCluster, sizeof(float));
    
    for (NSInteger j = 0; j < maxCluster; j++)
        for (NSInteger i = 0; i < maxCluster; i++)
            //if( i + j >= maxCluster)
            expectedMatrix[j * maxCluster + i] = summary[i * 3 + 1]/(total - 1) * summary[j * 3 + 2] * summary[j * 3 + 1];

            
    for (NSInteger j = 0; j < maxCluster; j++){
        for (NSInteger i = 0; i < maxCluster; i++)
            printf("%.3f ", expectedMatrix[j * maxCluster + i]);
        printf("\n");
    }
    
    return summary;
}

-(float *)observedMatrixWithSummary:(float *)summary forAdjacencyMatrix:(NSArray *)matrix categoricalVariable:(NSInteger)indexOfCategoricalVariable{
    
    NSInteger total = self.segments;
    NSLog(@"Total are %li", total);
    NSInteger maxCluster = [self maxCategorical:indexOfCategoricalVariable];
    
    if(summary == NULL || maxCluster <= 0)
        return NULL;
    
    float *observedMatrix = calloc(maxCluster * maxCluster, sizeof(float));
    
    for (NSInteger i = 0; i < total; i++){
        NSArray *arr = matrix[i];
        NSInteger classCell = (NSInteger)self.computedData[indexOfCategoricalVariable][i] - 1;
        for (NSNumber *num in arr) {
            NSInteger classCellInteractee = (NSInteger)self.computedData[indexOfCategoricalVariable][num.intValue - 1] - 1;
            observedMatrix[classCell * maxCluster + classCellInteractee] += 1.0f;
        }
    }
    
    for (NSInteger j = 0; j < maxCluster; j++){
        for (NSInteger i = 0; i < maxCluster; i++)
            printf("%.3f ", observedMatrix[j * maxCluster + i]);
        printf("\n");
    }
    
    return summary;
}

-(void)poligonizeFieldWithMarchingCubes{
    
    __weak IMC3DMask * weakself = self;
    [self openIfNecessaryAndPerformBlock:^{
        
        //Release any previous memory
        [self releaseVerts];
        
        //Adapted from http://paulbourke.net/geometry/polygonise/
        
        //Tritable with the edges that are cut by the corresponding triangles for each index of covered vertexes
        int triTable[256][16] =
        {{-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 1, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 8, 3, 9, 8, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 2, 10, 0, 2, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {2, 8, 3, 2, 10, 8, 10, 9, 8, -1, -1, -1, -1, -1, -1, -1},
            {3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 11, 2, 8, 11, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 9, 0, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 11, 2, 1, 9, 11, 9, 8, 11, -1, -1, -1, -1, -1, -1, -1},
            {3, 10, 1, 11, 10, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 10, 1, 0, 8, 10, 8, 11, 10, -1, -1, -1, -1, -1, -1, -1},
            {3, 9, 0, 3, 11, 9, 11, 10, 9, -1, -1, -1, -1, -1, -1, -1},
            {9, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 3, 0, 7, 3, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 1, 9, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 1, 9, 4, 7, 1, 7, 3, 1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 4, 7, 3, 0, 4, 1, 2, 10, -1, -1, -1, -1, -1, -1, -1},
            {9, 2, 10, 9, 0, 2, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1},
            {2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, -1, -1, -1, -1},
            {8, 4, 7, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {11, 4, 7, 11, 2, 4, 2, 0, 4, -1, -1, -1, -1, -1, -1, -1},
            {9, 0, 1, 8, 4, 7, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1},
            {4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, -1, -1, -1, -1},
            {3, 10, 1, 3, 11, 10, 7, 8, 4, -1, -1, -1, -1, -1, -1, -1},
            {1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, -1, -1, -1, -1},
            {4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, -1, -1, -1, -1},
            {4, 7, 11, 4, 11, 9, 9, 11, 10, -1, -1, -1, -1, -1, -1, -1},
            {9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 5, 4, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 5, 4, 1, 5, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {8, 5, 4, 8, 3, 5, 3, 1, 5, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 0, 8, 1, 2, 10, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1},
            {5, 2, 10, 5, 4, 2, 4, 0, 2, -1, -1, -1, -1, -1, -1, -1},
            {2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, -1, -1, -1, -1},
            {9, 5, 4, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 11, 2, 0, 8, 11, 4, 9, 5, -1, -1, -1, -1, -1, -1, -1},
            {0, 5, 4, 0, 1, 5, 2, 3, 11, -1, -1, -1, -1, -1, -1, -1},
            {2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, -1, -1, -1, -1},
            {10, 3, 11, 10, 1, 3, 9, 5, 4, -1, -1, -1, -1, -1, -1, -1},
            {4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, -1, -1, -1, -1},
            {5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, -1, -1, -1, -1},
            {5, 4, 8, 5, 8, 10, 10, 8, 11, -1, -1, -1, -1, -1, -1, -1},
            {9, 7, 8, 5, 7, 9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 3, 0, 9, 5, 3, 5, 7, 3, -1, -1, -1, -1, -1, -1, -1},
            {0, 7, 8, 0, 1, 7, 1, 5, 7, -1, -1, -1, -1, -1, -1, -1},
            {1, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 7, 8, 9, 5, 7, 10, 1, 2, -1, -1, -1, -1, -1, -1, -1},
            {10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, -1, -1, -1, -1},
            {8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, -1, -1, -1, -1},
            {2, 10, 5, 2, 5, 3, 3, 5, 7, -1, -1, -1, -1, -1, -1, -1},
            {7, 9, 5, 7, 8, 9, 3, 11, 2, -1, -1, -1, -1, -1, -1, -1},
            {9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, -1, -1, -1, -1},
            {2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, -1, -1, -1, -1},
            {11, 2, 1, 11, 1, 7, 7, 1, 5, -1, -1, -1, -1, -1, -1, -1},
            {9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, -1, -1, -1, -1},
            {5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, -1},
            {11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, -1},
            {11, 10, 5, 7, 11, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 0, 1, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 8, 3, 1, 9, 8, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1},
            {1, 6, 5, 2, 6, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 6, 5, 1, 2, 6, 3, 0, 8, -1, -1, -1, -1, -1, -1, -1},
            {9, 6, 5, 9, 0, 6, 0, 2, 6, -1, -1, -1, -1, -1, -1, -1},
            {5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8, -1, -1, -1, -1},
            {2, 3, 11, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {11, 0, 8, 11, 2, 0, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1},
            {0, 1, 9, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1, -1, -1, -1},
            {5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11, -1, -1, -1, -1},
            {6, 3, 11, 6, 5, 3, 5, 1, 3, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6, -1, -1, -1, -1},
            {3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9, -1, -1, -1, -1},
            {6, 5, 9, 6, 9, 11, 11, 9, 8, -1, -1, -1, -1, -1, -1, -1},
            {5, 10, 6, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 3, 0, 4, 7, 3, 6, 5, 10, -1, -1, -1, -1, -1, -1, -1},
            {1, 9, 0, 5, 10, 6, 8, 4, 7, -1, -1, -1, -1, -1, -1, -1},
            {10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4, -1, -1, -1, -1},
            {6, 1, 2, 6, 5, 1, 4, 7, 8, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7, -1, -1, -1, -1},
            {8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6, -1, -1, -1, -1},
            {7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9, -1},
            {3, 11, 2, 7, 8, 4, 10, 6, 5, -1, -1, -1, -1, -1, -1, -1},
            {5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11, -1, -1, -1, -1},
            {0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6, -1, -1, -1, -1},
            {9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6, -1},
            {8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6, -1, -1, -1, -1},
            {5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11, -1},
            {0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7, -1},
            {6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9, -1, -1, -1, -1},
            {10, 4, 9, 6, 4, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 10, 6, 4, 9, 10, 0, 8, 3, -1, -1, -1, -1, -1, -1, -1},
            {10, 0, 1, 10, 6, 0, 6, 4, 0, -1, -1, -1, -1, -1, -1, -1},
            {8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10, -1, -1, -1, -1},
            {1, 4, 9, 1, 2, 4, 2, 6, 4, -1, -1, -1, -1, -1, -1, -1},
            {3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4, -1, -1, -1, -1},
            {0, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {8, 3, 2, 8, 2, 4, 4, 2, 6, -1, -1, -1, -1, -1, -1, -1},
            {10, 4, 9, 10, 6, 4, 11, 2, 3, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6, -1, -1, -1, -1},
            {3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10, -1, -1, -1, -1},
            {6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1, -1},
            {9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3, -1, -1, -1, -1},
            {8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1, -1},
            {3, 11, 6, 3, 6, 0, 0, 6, 4, -1, -1, -1, -1, -1, -1, -1},
            {6, 4, 8, 11, 6, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {7, 10, 6, 7, 8, 10, 8, 9, 10, -1, -1, -1, -1, -1, -1, -1},
            {0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10, -1, -1, -1, -1},
            {10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0, -1, -1, -1, -1},
            {10, 6, 7, 10, 7, 1, 1, 7, 3, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7, -1, -1, -1, -1},
            {2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9, -1},
            {7, 8, 0, 7, 0, 6, 6, 0, 2, -1, -1, -1, -1, -1, -1, -1},
            {7, 3, 2, 6, 7, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7, -1, -1, -1, -1},
            {2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7, -1},
            {1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11, -1},
            {11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1, -1, -1, -1, -1},
            {8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6, -1},
            {0, 9, 1, 11, 6, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0, -1, -1, -1, -1},
            {7, 11, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 0, 8, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 1, 9, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {8, 1, 9, 8, 3, 1, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1},
            {10, 1, 2, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, 3, 0, 8, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1},
            {2, 9, 0, 2, 10, 9, 6, 11, 7, -1, -1, -1, -1, -1, -1, -1},
            {6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8, -1, -1, -1, -1},
            {7, 2, 3, 6, 2, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {7, 0, 8, 7, 6, 0, 6, 2, 0, -1, -1, -1, -1, -1, -1, -1},
            {2, 7, 6, 2, 3, 7, 0, 1, 9, -1, -1, -1, -1, -1, -1, -1},
            {1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6, -1, -1, -1, -1},
            {10, 7, 6, 10, 1, 7, 1, 3, 7, -1, -1, -1, -1, -1, -1, -1},
            {10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8, -1, -1, -1, -1},
            {0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7, -1, -1, -1, -1},
            {7, 6, 10, 7, 10, 8, 8, 10, 9, -1, -1, -1, -1, -1, -1, -1},
            {6, 8, 4, 11, 8, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 6, 11, 3, 0, 6, 0, 4, 6, -1, -1, -1, -1, -1, -1, -1},
            {8, 6, 11, 8, 4, 6, 9, 0, 1, -1, -1, -1, -1, -1, -1, -1},
            {9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6, -1, -1, -1, -1},
            {6, 8, 4, 6, 11, 8, 2, 10, 1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6, -1, -1, -1, -1},
            {4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9, -1, -1, -1, -1},
            {10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3, -1},
            {8, 2, 3, 8, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1},
            {0, 4, 2, 4, 6, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8, -1, -1, -1, -1},
            {1, 9, 4, 1, 4, 2, 2, 4, 6, -1, -1, -1, -1, -1, -1, -1},
            {8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1, -1, -1, -1, -1},
            {10, 1, 0, 10, 0, 6, 6, 0, 4, -1, -1, -1, -1, -1, -1, -1},
            {4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3, -1},
            {10, 9, 4, 6, 10, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 9, 5, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, 4, 9, 5, 11, 7, 6, -1, -1, -1, -1, -1, -1, -1},
            {5, 0, 1, 5, 4, 0, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1},
            {11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5, -1, -1, -1, -1},
            {9, 5, 4, 10, 1, 2, 7, 6, 11, -1, -1, -1, -1, -1, -1, -1},
            {6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5, -1, -1, -1, -1},
            {7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2, -1, -1, -1, -1},
            {3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6, -1},
            {7, 2, 3, 7, 6, 2, 5, 4, 9, -1, -1, -1, -1, -1, -1, -1},
            {9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7, -1, -1, -1, -1},
            {3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0, -1, -1, -1, -1},
            {6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8, -1},
            {9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7, -1, -1, -1, -1},
            {1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4, -1},
            {4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10, -1},
            {7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10, -1, -1, -1, -1},
            {6, 9, 5, 6, 11, 9, 11, 8, 9, -1, -1, -1, -1, -1, -1, -1},
            {3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5, -1, -1, -1, -1},
            {0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11, -1, -1, -1, -1},
            {6, 11, 3, 6, 3, 5, 5, 3, 1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6, -1, -1, -1, -1},
            {0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10, -1},
            {11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5, -1},
            {6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3, -1, -1, -1, -1},
            {5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2, -1, -1, -1, -1},
            {9, 5, 6, 9, 6, 0, 0, 6, 2, -1, -1, -1, -1, -1, -1, -1},
            {1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8, -1},
            {1, 5, 6, 2, 1, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6, -1},
            {10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0, -1, -1, -1, -1},
            {0, 3, 8, 5, 6, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {10, 5, 6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {11, 5, 10, 7, 5, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {11, 5, 10, 11, 7, 5, 8, 3, 0, -1, -1, -1, -1, -1, -1, -1},
            {5, 11, 7, 5, 10, 11, 1, 9, 0, -1, -1, -1, -1, -1, -1, -1},
            {10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1, -1, -1, -1, -1},
            {11, 1, 2, 11, 7, 1, 7, 5, 1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11, -1, -1, -1, -1},
            {9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7, -1, -1, -1, -1},
            {7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2, -1},
            {2, 5, 10, 2, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1},
            {8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5, -1, -1, -1, -1},
            {9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2, -1, -1, -1, -1},
            {9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2, -1},
            {1, 3, 5, 3, 7, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 7, 0, 7, 1, 1, 7, 5, -1, -1, -1, -1, -1, -1, -1},
            {9, 0, 3, 9, 3, 5, 5, 3, 7, -1, -1, -1, -1, -1, -1, -1},
            {9, 8, 7, 5, 9, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {5, 8, 4, 5, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1},
            {5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0, -1, -1, -1, -1},
            {0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5, -1, -1, -1, -1},
            {10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4, -1},
            {2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8, -1, -1, -1, -1},
            {0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11, -1},
            {0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5, -1},
            {9, 4, 5, 2, 11, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4, -1, -1, -1, -1},
            {5, 10, 2, 5, 2, 4, 4, 2, 0, -1, -1, -1, -1, -1, -1, -1},
            {3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9, -1},
            {5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2, -1, -1, -1, -1},
            {8, 4, 5, 8, 5, 3, 3, 5, 1, -1, -1, -1, -1, -1, -1, -1},
            {0, 4, 5, 1, 0, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5, -1, -1, -1, -1},
            {9, 4, 5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 11, 7, 4, 9, 11, 9, 10, 11, -1, -1, -1, -1, -1, -1, -1},
            {0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11, -1, -1, -1, -1},
            {1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11, -1, -1, -1, -1},
            {3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4, -1},
            {4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2, -1, -1, -1, -1},
            {9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3, -1},
            {11, 7, 4, 11, 4, 2, 2, 4, 0, -1, -1, -1, -1, -1, -1, -1},
            {11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4, -1, -1, -1, -1},
            {2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9, -1, -1, -1, -1},
            {9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7, -1},
            {3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10, -1},
            {1, 10, 2, 8, 7, 4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 9, 1, 4, 1, 7, 7, 1, 3, -1, -1, -1, -1, -1, -1, -1},
            {4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1, -1, -1, -1, -1},
            {4, 0, 3, 7, 4, 3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {4, 8, 7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {9, 10, 8, 10, 11, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 0, 9, 3, 9, 11, 11, 9, 10, -1, -1, -1, -1, -1, -1, -1},
            {0, 1, 10, 0, 10, 8, 8, 10, 11, -1, -1, -1, -1, -1, -1, -1},
            {3, 1, 10, 11, 3, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 2, 11, 1, 11, 9, 9, 11, 8, -1, -1, -1, -1, -1, -1, -1},
            {3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9, -1, -1, -1, -1},
            {0, 2, 11, 8, 0, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {3, 2, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {2, 3, 8, 2, 8, 10, 10, 8, 9, -1, -1, -1, -1, -1, -1, -1},
            {9, 10, 2, 0, 9, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8, -1, -1, -1, -1},
            {1, 10, 2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {1, 3, 8, 9, 1, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 9, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {0, 3, 8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},
            {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1}};
        
        //Prepare and index of how many necessary triangles are necessary for each index (summarizes the other table)
        unsigned * triangle_numbers = (unsigned *)calloc(256, sizeof(unsigned));
        for(int a = 1; a < 255; ++a){
            unsigned tri = 0;
            for(int b = 0; triTable[a][b] != -1; b+=3)
                tri++;
            triangle_numbers[a] = tri;
        }

        //Get copy of al context values
        NSLog(@"Starting polygonizing process");
        NSInteger planeWidth = weakself.width;
        NSLog(@"Plane width %li", planeWidth);
        NSInteger planeHeight = weakself.height;
        NSInteger planeArea = planeWidth * planeHeight;
        NSInteger parseW =  weakself.width - 1;
        NSInteger parseH =  weakself.height - 1;
        NSInteger parseS =  weakself.slices - 1;
        int * maskIds = weakself.maskIds;
        NSInteger segments = weakself.segmentedUnits;
        
        //Array of arrays. One per cell, and then will hold the char masks
        NSMutableArray *arrCollected = [NSMutableArray arrayWithCapacity:self.segmentedUnits];
        for(int a = 0; a < segments; ++a)
            [arrCollected addObject:[NSMutableArray array]];
        
        //Will keep a few counters of analyzed cells and discardable hits
        NSInteger discardable = 0;
        int * total_trinagles = (int *)calloc(segments, sizeof(int));
        
        //Loop through mask, add cases to arrCollected, increment discardable and total triangles as required
        NSInteger offset = 0;
        for(NSInteger s = 0; s < parseS; ++s){
            for(NSInteger h = 0; h < parseH; ++h){
                for(NSInteger w = 0; w < parseW; ++w){
                    int cubeVertexes[] = {0, 0, 0, 0, 0, 0, 0, 0};
                    NSInteger lowerPlane = offset + planeArea;
                    cubeVertexes[0] = maskIds[lowerPlane];
                    cubeVertexes[1] = maskIds[lowerPlane + 1];
                    cubeVertexes[2] = maskIds[lowerPlane + planeWidth + 1];
                    cubeVertexes[3] = maskIds[lowerPlane + planeWidth];
                    cubeVertexes[4] = maskIds[offset];
                    cubeVertexes[5] = maskIds[offset + 1];
                    cubeVertexes[6] = maskIds[offset + planeWidth + 1];
                    cubeVertexes[7] = maskIds[offset + planeWidth];
                    offset++;
                    
                    //Quick analysis to avoid procesing when all zeroes
                    BOOL someStuff = NO;
                    for(int l = 0; l < 8; ++l){
                        if(cubeVertexes[l] != 0){
                            someStuff = YES;
                            break;
                        }
                    }
                    if(someStuff){
                        //Check involved cells
                        NSMutableSet *cellsInvolved = [NSMutableSet set];
                        for(int l = 0; l < 8; ++l)
                            if(cubeVertexes[l] != 0)
                                [cellsInvolved addObject:@(cubeVertexes[l])];
                        
                        //Check involved cells one by one
                        for(NSNumber *cellId in cellsInvolved){
                            unsigned char cellMask = 0;
                            int val = cellId.intValue;
                            //Generate mask indentifier
                            for(int l = 0; l < 8; ++l){
                                if(val == cubeVertexes[l]){
                                    cellMask |= 1 << l;
                                }
                            }
                            if(cellMask == 0)
                                continue;
                            
                            //Increment discardable
                            if(cellMask == 255){
                                discardable++;
                                continue;
                            }
                            //Add mask to results and increment number of triangles per cell
                            [[arrCollected objectAtIndex:val-1]addObject:@[@(s), @(h), @(w), @(cellMask)]];
                            total_trinagles[val - 1] += triangle_numbers[cellMask];
                        }
                    }
                }
                offset++;//To account for the fact that we have all dimensions cut by 1
            }
            offset += planeWidth;//To account for the fact that we have all dimensions cut by 1 a line is missing
        }
        
        NSInteger totalHits = 0;
        for(NSArray *arr in arrCollected)
            totalHits += arr.count;
        
        NSLog(@"Finished mask analysis %li hits, valid %li, estimated %li triangles", totalHits, totalHits - discardable, (totalHits - discardable) * 3);
        
        //Create this lookup table of vertex positions for the mid points of the 12 edges of a cube, will form triangles with that and with coordinates of hit
        
        #define HALF 0.5f
        #define WHOLE 1.0f
        
        float edgePoints[12][3] = {
            {HALF, 0.0, WHOLE},
            {WHOLE, HALF, WHOLE},
            {HALF, WHOLE, WHOLE},
            {0.0, HALF, WHOLE},
            {HALF, 0.0, 0.0},
            {WHOLE, HALF, 0.0},
            {HALF, WHOLE, 0.0},
            {0.0, HALF, 0.0},
            {0.0, 0.0, HALF},
            {WHOLE, 0.0, HALF},
            {WHOLE, WHOLE, HALF},
            {0.0, WHOLE, HALF},
        };
        
        //Count the total number of polygons
        unsigned totalTriangles = 0;
        weakself.cellTriangleOffsets = (unsigned *)calloc(segments, sizeof(unsigned));
        for(int a = 0; a < segments; ++a){
            totalTriangles += total_trinagles[a];
            weakself.cellTriangleOffsets[a] = totalTriangles;
        }
        
        //Allocate buffer for vertex and normal data (3(3) elements each, x, y, z, (nx, ny, nz) for 3 vertexes)
        NSLog(@"Total triangles are %i", totalTriangles);
        weakself.numberOfTriangleVertices = (int)totalTriangles * 3;
        weakself.verts = (float *)calloc(self.numberOfTriangleVertices * 3, sizeof(float));
        
        float * copyPointVerts = weakself.verts;
        
        NSInteger cursor = 0;
        NSMutableArray *inOrderUniqueVertexes = @[].mutableCopy;////
        NSInteger counterDistinctVertexes = 0;////
        
        for(NSArray *arr in arrCollected){
            //All vertexes as independent
//            for(NSArray * coordsPlusTrilistVal in arr){
//                float s = [coordsPlusTrilistVal[0]floatValue];
//                float h = [coordsPlusTrilistVal[1]floatValue];
//                float w = [coordsPlusTrilistVal[2]floatValue];
//                unsigned char mask = (unsigned char)[coordsPlusTrilistVal[3]intValue];
//                for(int a = 0; triTable[mask][a] != -1; a +=3){
//                    for (unsigned char v = 0; v < 3; ++v) {
//                        float * v_data = edgePoints[triTable[mask][a + v]];
//
//                        copyPointVerts[cursor + 0] = w + v_data[0];
//                        copyPointVerts[cursor + 1] = h + v_data[1];
//                        copyPointVerts[cursor + 2] = s + v_data[2];
//
//                        cursor += 3;
//                    }
//                }
//            }
            
            //Individual vertexes to do indexing ////
            NSMutableArray *inOrderUniqueVertexesObject = @[].mutableCopy;
            NSMutableDictionary * trackerVertex = @{}.mutableCopy;
            
            for(NSArray * coordsPlusTrilistVal in arr){
                float s = [coordsPlusTrilistVal[0]floatValue];
                float h = [coordsPlusTrilistVal[1]floatValue];
                float w = [coordsPlusTrilistVal[2]floatValue];
                unsigned char mask = (unsigned char)[coordsPlusTrilistVal[3]intValue];
                for(int a = 0; triTable[mask][a] != -1; a +=3){
                    for (unsigned char v = 0; v < 3; ++v) {
                        float * v_data = edgePoints[triTable[mask][a + v]];
                        float x = w + v_data[0];
                        float y = h + v_data[1];
                        float z = s + v_data[2];
                        
                        NSString *str = [NSString stringWithFormat:@"%.2f_%.2f_%.2f", x, y, z];
                        NSNumber * index = trackerVertex[str];
                        if(!index){
                            index = @(counterDistinctVertexes);
                            trackerVertex[str] = [index copy];
                            counterDistinctVertexes++;
                            [inOrderUniqueVertexesObject addObject:coordsPlusTrilistVal];
                        }
                        
                        copyPointVerts[cursor] = index.floatValue;

                        cursor ++;
                    }
                }
            }
            [inOrderUniqueVertexes addObjectsFromArray:inOrderUniqueVertexesObject];
            ////
        }
        NSLog(@"Found %li unique vertexes (%li) with their corresponding %li indexes", inOrderUniqueVertexes.count, counterDistinctVertexes, cursor);
        free(triangle_numbers);
        free(total_trinagles);
        NSLog(@"Done polygonizing");
    }];
}

-(void)dealloc{
    [self clearComputedData];
    [self releaseMask];
    [self releaseVerts];
}

@end
