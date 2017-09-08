//
//  IMCPixelMap.m
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelMap.h"
#import "IMC_TIFFLoader.h"
#import "IMCImageGenerator.h"
#import "NSImage+OpenCV.h"
#import "IMCPixelTraining.h"

@implementation IMCPixelMap

-(IMCImageStack *)imageStack{
    return (IMCImageStack *)self.parent;
}
-(IMCPixelTraining *)whichTraining{
    for (IMCPixelTraining *train in self.imageStack.pixelTrainings)
        if([train.itemHash isEqualToString:self.whichTrainingHash])
            return train;
    
    return nil;
}
-(NSString *)whichTrainingHash{
    return self.jsonDictionary[JSON_DICT_PIXEL_MAP_WHICH_TRAINING];
}

-(void)setParent:(IMCNodeWrapper *)parent{
    if(!self.parent && parent){
        if(!parent.jsonDictionary[JSON_DICT_PIXEL_MAPS])
            parent.jsonDictionary[JSON_DICT_PIXEL_MAPS] = @[].mutableCopy;
        if(![parent.jsonDictionary[JSON_DICT_PIXEL_MAPS] containsObject:self.jsonDictionary])
            [parent.jsonDictionary[JSON_DICT_PIXEL_MAPS] addObject:self.jsonDictionary];
    }
    [super setParent:parent];
}

-(NSString *)itemSubName{
    if(self.jsonDictionary[JSON_DICT_ITEM_NAME])
        return self.jsonDictionary[JSON_DICT_ITEM_NAME];
    return self.jsonDictionary[JSON_DICT_ITEM_NAME];
//    return [@"pixel map" stringByAppendingString:self.jsonDictionary[JSON_DICT_PIXEL_MAP_HASH]];
}

-(NSString *)itemName{
    return self.imageStack.itemName;
//    if(self.jsonDictionary[JSON_DICT_ITEM_NAME])
//        return self.jsonDictionary[JSON_DICT_ITEM_NAME];
//    return self.jsonDictionary[JSON_DICT_ITEM_NAME];
}

-(BOOL)isSegmentation{
    return [self.jsonDictionary[JSON_DICT_PIXEL_MAP_FOR_SEGMENTATION]boolValue];
}
-(void)setIsSegmentation:(BOOL)isSegmentation{
    self.jsonDictionary[JSON_DICT_PIXEL_MAP_FOR_SEGMENTATION] = [NSNumber numberWithBool:isSegmentation];
}

-(void)loadLayerDataWithBlock:(void (^)())block{
    
    NSData *data = [NSData dataWithContentsOfFile:self.absolutePath];
    NSInteger pix = self.imageStack.numberOfPixels;
    if(data && data.length == pix * sizeof(float)){
        float * floatData = (float *)data.bytes;
        
        self.channels = @[@"Predictions", @"Certainty"].mutableCopy;
        self.origChannels = @[@"Predictions", @"Certainty"].mutableCopy;
        
        [self clearBuffers];
        [self allocateBufferWithPixels:pix];
        
        for (NSInteger i = 0; i < pix; i++){
            float val = floatData[i];
            float classs = floorf(val);
            float prob = val - classs;
            self.stackData[0][i] = classs;
            self.stackData[1][i] = prob;
        }
        self.isLoaded = YES;
        if(block)block();
        //[super.super loadLayerDataWithBlock:block];//Bc subclass of IMCImageStack, not IMCNodeWrapper
    }
}

-(CGImageRef)pMap{
    if(!self.stackData)
        return NULL;
    if(!self.stackData[0])
        return NULL;
    
    NSInteger pixels = self.imageStack.numberOfPixels;
    NSInteger cats = 0;
    for (NSInteger i = 0; i < pixels; i++) {
        if(floorf(self.stackData[0][i])> cats)
            cats = floorf(self.stackData[0][i]);
    }
    
    NSArray *colors = [NSColor collectColors:cats withColoringType:1 minumAmountColors:cats];
    
    NSMutableArray *array = @[].mutableCopy;
    for (int j = 0; j < cats; j++) {
        UInt8 * dataPic = (UInt8 *)calloc(pixels, sizeof(UInt8));
        for (NSInteger i = 0; i < pixels; i++) {
            //float result = self.stackData[0][i];
            float classResult = self.stackData[0][i];
            float prob = self.stackData[1][i];
            dataPic[i] = classResult == j + 1?(UInt8)(255*prob):0;
        }
        CGImageRef ref = [IMCImageGenerator imageFromCArrayOfValues:dataPic color:colors[j] width:self.width height:self.height startingHueScale:0 hueAmplitude:255 direction:YES ecuatorial:NO brightField:NO];
        [array addObject:(__bridge id)ref];
        free(dataPic);
    }
    
    return [[IMCImageGenerator imageWithArrayOfCGImages:array width:self.width height:self.height blendMode:kCGBlendModeScreen]gaussianBlurred:1].CGImage;
}

-(void)savePixelMapPredictions{
    
    if(!self.stackData){
        [General runAlertModalWithMessage:@"Calculate pixel map first"];
        return;
    }
    NSInteger pix = self.imageStack.numberOfPixels;
    float * all = (float *)calloc(pix, sizeof(float));
    for (NSInteger i = 0; i < pix; i++)
        all[i] = self.stackData[0][i] + self.stackData[1][i];
    
    NSData *data = [NSData dataWithBytes:all length:self.imageStack.numberOfPixels * sizeof(float)];
    
    self.relativePath = [NSString stringWithFormat:@"%@/%@_%@_pred.pmap", self.workingFolderRealative, self.itemHash.copy, self.isSegmentation?@"seg":@""];
    
    [data writeToFile:self.absolutePath atomically:YES];
    free(all);
}

-(void)saveColorizedPixelMapPredictions{
    CGImageRef pMap = [self pMap];
    NSImage *image = [[NSImage alloc]initWithCGImage:pMap size:self.size];
    NSData *data = [image TIFFRepresentation];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@_%@_pmap.tiff", self.imageStack.workingFolder, self.itemHash, [self isSegmentation]?@"seg":@""];
    [data writeToFile:path atomically:YES];
    CFRelease(pMap);
    
}

@end
