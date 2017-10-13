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

@interface IMC3DMask(){
    int * maskIds;
}

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger slices;

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
        return 0;

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
-(int)checkCandidates:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane width:(NSInteger)width{
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
                        return 1 + [self checkCandidates:test fullMaskLength:fullMaskLength planLength:plane width:width];
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

-(void)extractMaskFromRender{
    IMC3DHandler *handler = self.threeDHandler;
    
    self.width = handler.width;
    self.height = handler.height;
    self.slices = handler.images;
    
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  handler.images;
    NSInteger channel = self.channel;
    NSInteger schannel = self.substractChannel;
    
    float final = self.threshold;

    [self releaseMask];
    maskIds = calloc(fullMask, sizeof(int));
    
    if(self.type == MASK3D_WATERSHED){
        int cellId = 1;
        for (float analyze = 1.0f; analyze > final; analyze -= self.stepWatershed) {
            //Add Values
            float analyzeAdded = analyze;
            NSLog(@"%f step", analyzeAdded);
            
            //        if(schannel > 0)
            //            analyzeAdded *= (1 - analyze);
            
            for (NSInteger i = 0; i <handler.images; i++){
                NSInteger offset = allLength * i;
                if(handler.allBuffer[i]){
                    if(handler.allBuffer[i][channel]){
                        for (NSInteger j = 0; j < allLength; j++){
                            if(maskIds[offset + j] == 0){
                                float val = handler.allBuffer[i][channel][j];
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
            
            for (NSInteger i = 0; i <handler.images; i++){
                NSInteger offset = allLength * i;
                if(handler.allBuffer[i])
                    if(handler.allBuffer[i][channel])
                        for (NSInteger j = 0; j < allLength; j++){
                            if(maskIds[offset + j] == -1){
                                int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                                if(qual >= self.minKernel){//Promote all
                                    [self assignId:cellId toIndex:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                                    cellId++;
                                }
                            }
                        }
            }
        }
        NSLog(@"Assigned %i", cellId);
    }
    if(self.type == MASK3D_THRESHOLD || self.type == MASK3D_THRESHOLD_SEGMENT){
        float analyze = self.threshold;
        for (NSInteger i = 0; i <handler.images; i++){
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++)
                        if(maskIds[offset + j] == 0){
                            float val = handler.allBuffer[i][channel][j];
                            if(schannel > 0 && handler.allBuffer[i][schannel])
                                val -= handler.allBuffer[i][schannel][j];
                            if(val >= analyze)
                                maskIds[offset + j] = -1;
                        }
        }
        int cellId = 1;
        for (NSInteger i = 0; i <handler.images; i++){NSLog(@"IM");
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++)
                        if(maskIds[offset + j] == -1){
                            int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                            if(qual >= self.minKernel){//Promote all
                                [self assignId:self.type == MASK3D_THRESHOLD_SEGMENT?cellId:1 toIndex:offset + j fullMaskLength:fullMask planLength:allLength width:self.width];
                                cellId++;
                            }
                        }
            
        }
        NSLog(@"Assigned %i", cellId);
    }
    //Reset negative values
    [self resetNegs:fullMask];
    
    //Expand
    [self expand];
    
    //Prepare the 3D buffer handler
    [self passToHandler];
    
    //Load up node
    [super loadLayerDataWithBlock:nil];
    
    //Save file with mask
    [self saveData];
}

-(void)expand{
    
    IMC3DHandler *handler = self.threeDHandler;
    
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  handler.images;
    NSInteger width = self.width;
    
    for (NSInteger i = 0; i < self.expansion; i++) {
        for (NSInteger j = 0; j < fullMask; j++) {

            int val = maskIds[j];
            if(val > 0){
                NSInteger candidates[6] = {j - width,
                    j + width,
                    j - 1,
                    j + 1,
                    j - i % 2 == 0 ? fullMask : allLength,
                    j + i % 2 == 0 ? fullMask : allLength
                };
                for (int m = 0; m < 6;  m++)
                    if(candidates[m] >= 0 && candidates[m] < fullMask)
                        if(maskIds[candidates[m]] == 0)
                            maskIds[candidates[m]] = -val;
            }
        }
        for (NSInteger j = 0; j < fullMask; j++)
            if(maskIds[j] < 0)
                maskIds[j] = -maskIds[j];
        
    }
}

-(void)passToHandler{
    if(maskIds){
        NSInteger allLength = self.width * self.height;
        //NSInteger fullMaskLength = allLength * self.slices;
        
        [self.threeDHandler startBufferForImages:self.slices channels:1 width:self.width height:self.height];
        
        int randomColors = 12;
        float pre[randomColors];
        float pass = .95f/randomColors;
        for (int i = 0; i < randomColors; i++) {
            pre[i] = 0.05f + pass * i;
        }
        
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
        //[self.threeDHandler meanBlurModelWithKernel:3 forChannels:[NSIndexSet indexSetWithIndex:0] mode:self.blurMode];
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
-(void)saveData{
    if(maskIds){
        NSInteger elems = self.slices * self.width * self.height;
        NSInteger count = elems * sizeof(int);
        int * compMask = malloc(count);
        
        int cursorComp = 0;
        int scopeValue = maskIds[0], inRow = 1;;
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
-(void)deleteSelf{
    NSString *path = [self pathFile];
    NSError *error = nil;
    [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    if(error)
        NSLog(@"Remove returned error: %@", [error localizedDescription]);
    [self.coordinator remove3DNode:self];
}
-(void)loadLayerDataWithBlock:(void (^)())block{
    
    NSString *path = [self pathFile];
    NSData *data = [NSData dataWithContentsOfFile:path];
    [self releaseMask];
    NSInteger elems = self.slices * self.width * self.height;
    NSInteger count = elems * sizeof(int);
    maskIds = malloc(count);
    
    if(data){
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
    [super loadLayerDataWithBlock:nil];
}
-(void)unLoadLayerDataWithBlock:(void (^)())block{
    [self releaseMask];
    [super unLoadLayerDataWithBlock:block];
}

@end
