//
//  IMC3DHandler.m
//  3DIMC
//
//  Created by Raul Catena on 1/31/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC3DHandler.h"
#import "IMCImageGenerator.h"
#import "memusage.h"

@interface IMC3DHandler(){
    float *deltas_z;
    float *thicknesses;
}
@end

@implementation IMC3DHandler

-(instancetype)init{
    self = [super init];
    if (self) {
        self.allBuffer = NULL;
        self.defaultZ = 2.0f;
    }
    return self;
}

-(BOOL)isReady{
    if (self.allBuffer != NULL) {
        return YES;
    }
    return NO;
}

-(BOOL)memoryTest{
    float free = [memusage toGB:[memusage memUsage:MEM_INFO_FREE]];

    NSLog(@"Gbytes free %f size requested %fGB", free, [self gigaBytes]);

    if([self gigaBytes] > free){
        [General runAlertModalWithMessage:[NSString stringWithFormat:@"Not enough memory, %.2f GB of free RAM required. You have %.2f currently available", [memusage toGB:self.width * self.height], free]];
        return NO;
    }
    return YES;
}

#pragma mark Z handling

-(float *)zValues{
    if(deltas_z == NULL)
        [self makeDefaultZValues];
    return deltas_z;
}
-(float *)thicknesses{
    if(thicknesses == NULL)
        [self makeDefaultThicknesses];
    return thicknesses;
}
-(void)cleanDeltas{
    if(deltas_z != NULL){
        free(deltas_z);
        deltas_z = NULL;
    }
}
-(void)makeDefaultZValues{
    [self cleanDeltas];
    deltas_z = (float *)calloc(self.images, sizeof(float));
    for(int i = 0; i < self.images; i++)
        deltas_z[i] = 2.0f * i;
}
-(void)cleanThicknesses{
    if(thicknesses != NULL){
        free(thicknesses);
        thicknesses = NULL;
    }
}
-(void)makeDefaultThicknesses{
    [self cleanThicknesses];
    thicknesses = (float *)calloc(self.images, sizeof(float));
    for(int i = 0; i < self.images; i++)
        thicknesses[i] = 2.0f;
}
-(void)prepDeltasAndProportionsWithStacks{
    [self cleanDeltas];
    deltas_z = (float *)calloc(self.items.count, sizeof(float));
    [self cleanThicknesses];
    thicknesses = (float *)calloc(self.items.count, sizeof(float));
    
    float cumZ = .0f;
    
    for (IMCImageStack *stack in self.items) {
        NSInteger index = [self.items indexOfObject:stack];
        NSDictionary *dict;
        if([stack isMemberOfClass:[IMCComputationOnMask class]])
            dict = [self.loader metadataForImageStack:[(IMCComputationOnMask *)stack mask].imageStack];
        else if([stack isMemberOfClass:[IMCImageStack class]])
            dict = [self.loader metadataForImageStack:stack];
        
        NSString *val = dict[@"z_pos"];
        float delta_z = val.floatValue;
        if(val && ![val isEqualToString:@""] && delta_z >=.0f && delta_z <=10000.0f)
            cumZ += delta_z;
        else
            cumZ += self.defaultZ;
        
        if(index == 0)
            cumZ = 0;
        
        deltas_z[index] = cumZ;
        
        val = dict[@"thickness"];
        float thickness = val.floatValue;
        if(val && ![val isEqualToString:@""] && thickness >=.0f && thickness <=100.0f)
            thicknesses[index] = thickness;
        else
            thicknesses[index] = self.defaultZ;
    }
    self.images = [self indexesArranged].count;
}
-(float)totalThickness{
    if(thicknesses == NULL || deltas_z == NULL || self.images == 0)
        return .0f;
    return thicknesses[self.images-1] + deltas_z[self.images - 1];
}

-(NSArray *)indexesArranged{
    NSMutableDictionary *dict = @{}.mutableCopy;
    for (NSInteger i = 0; i < self.items.count; i++) {
        float pos = deltas_z[i];
        NSString *key = [NSString stringWithFormat:@"%.2f", pos];
        NSMutableArray *found = dict[key];
        if(!found)
            found = @[].mutableCopy;
        [found addObject:@(i)];
        [dict setValue:found forKey:key];
    }
    NSMutableArray *arr = @[].mutableCopy;
    for (NSInteger i = 0; i < self.items.count; i++) {
        float pos = deltas_z[i];
        NSString *key = [NSString stringWithFormat:@"%.2f", pos];
        NSMutableArray *found = dict[key];
        if(![arr containsObject:found])
            [arr addObject:found];
    }
    return arr;
}
-(NSArray *)indexesArranged3DMask{
    NSMutableArray *arr = @[].mutableCopy;
    return arr;
}
-(NSInteger)internalSliceIndexForExternal:(NSInteger)external{
    NSArray *idx = [self indexesArranged];
    if(external < idx.count)
        return [[idx[external]firstObject]integerValue];
    return NSNotFound;
}
-(NSInteger)externalSliceIndexForInternal:(NSInteger)internal{
    NSArray *idx = [self indexesArranged];
    for (NSArray *arr in idx) {
        for(NSNumber *num in arr)
            if(num.integerValue == internal)
                return [idx indexOfObject:arr];
    }
    return NSNotFound;
}


-(void)startBufferForImages:(NSArray *)images channels:(NSInteger)channels width:(NSInteger)width height:(NSInteger)height{
    self.items = images;
    [self prepDeltasAndProportionsWithStacks];
    [self cleanMemory];
    
    self.channels = channels;
    self.width = width;
    self.height = height;
    
    //if([self memoryTest])return;
    
    self.allBuffer = (UInt8 ***)malloc(self.images * sizeof(UInt8 **));
    
    for (NSInteger i = 0; i < self.images; i++) {
        UInt8 ** imageBuff = (UInt8 **)calloc(channels, sizeof(UInt8 *));
        //for (NSInteger j = 0; j < channels; j++) {
        //    imageBuff[j] = (float *)calloc(width * height, sizeof(float));
        //}
        self.allBuffer[i] = imageBuff;
    }
    [self allocateMask];
}

#pragma mark mask stuff

-(void)cleanMaskMemory{
    if(self.showMask){
        free(self.showMask);
        self.showMask = NULL;
    }
}
-(void)setInterestProportions:(NSRect)interestProportions{
    _interestProportions = interestProportions;
    [self allocateMask];
}
-(void)allocateMask{
    [self cleanMaskMemory];
    self.showMask = (bool *)calloc(self.width * self.height, sizeof(bool));
    NSInteger total = self.width * self.height;
    for (NSInteger i = 0; i < total; i++) {
        NSInteger y = i/self.height;
        NSInteger x = i%self.height;
        
        if(y > self.height * self.interestProportions.origin.y
           && y < self.height * (self.interestProportions.origin.y + self.interestProportions.size.height)
           && x > self.width * self.interestProportions.origin.x
           && x < self.width * (self.interestProportions.origin.x + self.interestProportions.size.width)
           )
            self.showMask[i] = true;
    }
}

-(NSPoint)proportionalOffsetToCenter{
    return NSMakePoint((self.interestProportions.size.width/2 + self.interestProportions.origin.x - .5) * self.width,
                       (self.interestProportions.size.height/2 + self.interestProportions.origin.y - .5) * self.width
                       );
}

#pragma mark load data

-(void)addImageStackatIndex:(NSInteger)indexStack channel:(NSInteger)channel{
    indexStack = [self externalSliceIndexForInternal:indexStack];
    NSArray *internals = [self indexesArranged][indexStack];
    
    if(self.allBuffer[indexStack][channel])
    {
        free(self.allBuffer[indexStack][channel]);
        self.allBuffer[indexStack][channel] = NULL;
    }
    self.allBuffer[indexStack][channel] = (UInt8 *)calloc(self.width * self.height, sizeof(float));
    
    for (NSNumber *index in internals) {
        NSInteger internal = index.integerValue;
        IMCImageStack *stack = self.items[internal];
        
        [stack openIfNecessaryAndPerformBlock:^{
            CGImageRef image = [IMCImageGenerator whiteRotatedBufferForImage:stack
                                                                     atIndex:channel
                                                                superCanvasW:self.width superCanvasH:self.height];
            CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image));
            
            UInt8 * buf = (UInt8 *) CFDataGetBytePtr(rawData);
            NSInteger length = CFDataGetLength(rawData);

            for(int i=0; i<length; i++)
                self.allBuffer[indexStack][channel][i] += buf[i];
            
            CFRelease(rawData);
            CFRelease(image);
        }];
    }
}
-(void)addComputationAtIndex:(NSInteger)indexStack channel:(NSInteger)channel maskOption:(MaskOption)option maskType:(MaskType)type{
    
    indexStack = [self externalSliceIndexForInternal:indexStack];
    NSArray *internals = [self indexesArranged][indexStack];
    
    if(self.allBuffer[indexStack][channel])
    {
        free(self.allBuffer[indexStack][channel]);
        self.allBuffer[indexStack][channel] = NULL;
    }
    self.allBuffer[indexStack][channel] = (UInt8 *)calloc(self.width * self.height, sizeof(float));
    
    for (NSNumber *index in internals) {
        NSInteger internal = index.integerValue;
        
        IMCComputationOnMask *comp = self.items[internal];
        [comp.mask openIfNecessaryAndPerformBlock:^{
            [comp openIfNecessaryAndPerformBlock:^{
                
                CGImageRef ref = [IMCImageGenerator refForMaskComputation:comp indexes:@[@(channel)] coloringType:1 customColors:@[[NSColor whiteColor]] minNumberOfColors:1 width:self.width height:self.height withTransforms:YES blendMode:kCGBlendModeScreen maskOption:option maskType:type maskSingleColor:[NSColor whiteColor] brightField:NO];
                
                UInt8 *buf = [IMCImageGenerator bufferForImageRef:ref];
                
                NSInteger length = self.width * self.height;//CFDataGetLength(rawData);
                
                for(int i=0, k=0; i<length; i++, k+=4)
                    self.allBuffer[indexStack][channel][i] += buf[k];
                
                if(buf)
                    free(buf);
                if(ref)
                    CGImageRelease(ref);
                [comp clearCacheBuffers];
            }];
        }];
    }
}
-(void)addMask:(IMCPixelClassification *)mask atIndexOfStack:(NSInteger)indexStack maskOption:(MaskOption)option maskType:(MaskType)type{
    
    CGImageRef ref = [IMCImageGenerator refMask:mask coloringType:1 width:self.width height:self.height withTransforms:YES blendMode:kCGBlendModeScreen maskOption:option maskType:type maskSingleColor:[NSColor whiteColor]];
    
    UInt8 *buf = [IMCImageGenerator bufferForImageRef:ref];
    
    NSInteger length = self.width * self.height;//CFDataGetLength(rawData);
    
    if(self.allBuffer[indexStack][0])
    {
        free(self.allBuffer[indexStack][0]);
        self.allBuffer[indexStack][0] = NULL;
    }
    
    self.allBuffer[indexStack][0] = (UInt8 *)calloc(self.width * self.height, sizeof(UInt8));
    
    for(int i=0, k=0; i<length; i++, k+=4)
        self.allBuffer[indexStack][0][i] = buf[k] != 0? 1:0;
    
    if(buf)
        free(buf);
    if(ref)
        CFRelease(ref);
}

#pragma mark blur

-(void)meanBlurModelWithKernel:(NSInteger)kernel forChannels:(NSIndexSet *)channels  mode:(NSInteger)mode{
    threeDMeanBlur(self.allBuffer, self.width, self.height, self.images, channels, mode, self.showMask, deltas_z);
}

-(NSInteger)bytes{
    NSInteger add = 0;
    if (self.allBuffer) {
        for (NSInteger i = 0; i < self.images; i++) {
            add += sizeof(float **);
            if(self.allBuffer[i]){
                add += sizeof(float *);
                for (NSInteger j = 0; j < self.channels; j++) {
                    if(self.allBuffer[i][j])
                        add += (self.width * self.height);
                }
            }
        }
    }
    return add;//self.images * self.channels * self.width * self.height * sizeof(float);
}

-(float)megabytes{
    return [memusage toMB:[self bytes]];
}
-(float)gigaBytes{
    return [memusage toGB:[self bytes]];
}

-(void)cleanMemory{
    if(self.allBuffer){
        for (int i = 0; i < self.images; i++) {
            for (int j = 0; j < self.channels; j++) {
                if(self.allBuffer[i])
                    if(self.allBuffer[i][j]){
                        free(self.allBuffer[i][j]);
                        self.allBuffer[i][j] = NULL;
                    }
                
            }
            free(self.allBuffer[i]);
            self.allBuffer[i] = NULL;
        }
        free(self.allBuffer);
        self.allBuffer = NULL;
    }
}

-(void)dealloc{
    [self cleanMemory];
    [self cleanMaskMemory];
}

@end
