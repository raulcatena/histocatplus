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

@interface IMC3DMask(){
    int * maskIds;
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
                    test = testIndex + _width * cur;
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
    if(dic.allKeys.count > 1)
        return 0;
//    if(dic.allKeys.count > 0){
//        NSInteger max = 0;
//        NSNumber *key;
//        for (NSNumber *num in dic.allKeys) {
//            if([dic[num]integerValue]>max){
//                max = [dic[num]integerValue];
//                key = num;
//            }
//        }
//        return key.intValue;
//    }
    
    return -1;
}

-(void)recurseGiveId:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane cellId:(int)cellId{
    
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            for (int k = -1; k < 2; k++) {
                NSInteger test = testIndex + k * plane + j * _width + i;
//                if(test > 0 && test < fullMaskLength)
//                    if(maskIds[test] < 0)
//                        maskIds[test] = cellId;
                
                if(abs(i) == 1 && abs(j) == 1 && abs(k) == 1)
                    continue;
                if(test > 0 && test < fullMaskLength)
                    if(maskIds[test] == -1 && testIndex != test){
                        maskIds[test] = cellId;
                        [self recurseGiveId:test fullMaskLength:fullMaskLength planLength:plane cellId:cellId];
                    }
            }
        }
    }
    maskIds[testIndex] = cellId;
}

-(int)checkCandidates:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength planLength:(NSInteger)plane{
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            for (int k = -1; k < 2; k++) {
                if(abs(i) == 1 && abs(j) == 1 && abs(k) == 1)
                    continue;
                NSInteger test = testIndex + k * plane + j * _width + i;
                if(test > 0 && test < fullMaskLength)
                    if(maskIds[test] == -1 && testIndex != test){
                        maskIds[test] = 0;
                        return 1 + [self checkCandidates:test fullMaskLength:fullMaskLength planLength:plane];
                    }
            }
        }
    }
    return 0;
}

-(void)resetNegs:(NSInteger)allLength{
    for (NSInteger i = 0; i < allLength; i++)
        if(maskIds[i] < -1)
            maskIds[allLength] = -1;
}

-(void)extractMaskFromRender{
    IMC3DHandler *handler = self.threeDHandler;
    
    self.width = handler.width;
    self.height = handler.height;
    NSInteger allLength = self.width * self.height;
    NSInteger fullMask = allLength *  handler.images;
    NSInteger channel = self.channel;
    NSInteger schannel = self.substractChannel;
    
    float final = self.threshold;

    [self releaseMask];
    maskIds = calloc(fullMask, sizeof(int));
    
    int cellId = 1;
    for (float analyze = 1.0f; analyze > final; analyze -= 0.005) {
        //Add Values
        float analyzeAdded = analyze;
//        if(schannel > 0)
//            analyzeAdded *= (1 - analyze);
        for (NSInteger i = 0; i <handler.images; i++){
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++){
                        float val = handler.allBuffer[i][channel][j];
                        if(schannel > 0 && handler.allBuffer[i][schannel])
                            val *= (1.0f - handler.allBuffer[i][schannel][j]);
                        if(val >= analyzeAdded)
                            if(maskIds[offset + j] == 0)
                                maskIds[offset + j] = [self touchesId:offset + j fullMaskLength:fullMask planLength:allLength];
                    }

        }
        
        for (NSInteger i = 0; i <handler.images; i++){
            NSInteger offset = allLength * i;
            if(handler.allBuffer[i])
                if(handler.allBuffer[i][channel])
                    for (NSInteger j = 0; j < allLength; j++){
                        if(maskIds[offset + j] == -1){
                            int qual = [self checkCandidates:offset + j fullMaskLength:fullMask planLength:allLength];
                            //printf("%i ", qual);
                            if(qual >= self.minKernel){//Promote all
                                [self recurseGiveId:offset + j fullMaskLength:fullMask planLength:allLength cellId:cellId];
                                cellId++;
                            }
                        }
                    }
        }
        [self resetNegs:fullMask];
    }
    NSLog(@"Assigned %i", cellId);
    [self passToHandler:cellId];
    self.isLoaded = YES;
}
-(void)passToHandler:(int)cells{
    if(maskIds){
        NSInteger allLength = self.width * self.height;
        float divisor = (float)cells;
        if(self.threeDHandler.allBuffer)
            for (NSInteger i = 0; i < self.threeDHandler.images; i++) {
                NSInteger offSet = allLength * i;
                if(self.threeDHandler.allBuffer[i]){
                    if(self.threeDHandler.allBuffer[i][0] != NULL)
                        free(self.threeDHandler.allBuffer[i][0]);
                    self.threeDHandler.allBuffer[i][0] = calloc(allLength, sizeof(float));
                    for (NSInteger j = 0; j < allLength; j++){
                        if(maskIds[offSet + j] > 0)
                            printf("%i ", maskIds[offSet + j]);
                        self.threeDHandler.allBuffer[i][0][j] = maskIds[offSet + j] > 0 ? 0.25f + 0.15f*(maskIds[offSet + j]%5) : 0;
                    }
                }
            }
    }
}

-(void)releaseMask{
    if(maskIds){
        free(maskIds);
        maskIds = NULL;
    }
}

-(void)loadLayerDataWithBlock:(void (^)())block{
    [self extractMaskFromRender];
    [super loadLayerDataWithBlock:nil];
}
-(void)unLoadLayerDataWithBlock:(void (^)())block{

}

@end
