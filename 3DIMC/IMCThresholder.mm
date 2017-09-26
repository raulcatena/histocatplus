//
//  IMCThresholder.m
//  3DIMC
//
//  Created by Raul Catena on 3/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCThresholder.h"
#import "IMCPixelClassification.h"
#import "IMCImageGenerator.h"
#import "IMCMasks.h"
#import "NSImage+OpenCV.h"

@interface IMCThresholder()
@property (nonatomic, strong) IMCPixelClassification *inv;
@end

@implementation IMCThresholder

-(void)createMap{
    self.mask = [[IMCPixelClassification alloc]init];
    [self configureNewMask:self.mask];
}
-(void)configureNewMask:(IMCPixelClassification *)mask{
    mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_CELL] = @NO;
    mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_PAINTED] = @(self.isPaint);
    mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_THRESHOLD] = @(!self.isPaint);
    mask.itemName = self.mask.itemHash;
    mask.itemSubName = self.label;
}
-(NSString *)label{
    if(!_label)
        _label = [self.isPaint?@"Painted_":@"Threshold_" stringByAppendingString:[IMCUtils randomStringOfLength:6]];
    return _label;
}
-(NSMutableDictionary *)jsonForNewThresholdMask{
    return @{JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_CHANNEL: @(self.channelIndex),
             JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FRAMER: @(self.framerIndex),
           JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_THRESHOLD: @(self.thresholdValue),
             JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FLATTEN: @(self.flatten),
            JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_GAUSSIAN: @(self.blur),
            JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_INVERSE: @(self.saveInverse),
                                                          }.mutableCopy;
}
-(void)setMask:(IMCPixelClassification *)mask{
    _mask = mask;
    
    NSInteger length = mask?mask.imageStack.numberOfPixels:self.stack.numberOfPixels;
    if(!self.paintMask)
        self.paintMask = (int *)calloc(length, sizeof(int));

    if(_mask.mask)
        for (NSInteger i = 0; i < length; i++)
            self.paintMask[i] = _mask.mask[i];
    
    NSMutableDictionary *options = _mask.thresholdSettings;
    if(options){
        self.channelIndex = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_CHANNEL]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_CHANNEL]integerValue]:0;
        self.framerIndex = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FRAMER]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FRAMER]integerValue]:0;
        self.thresholdValue = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_THRESHOLD]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_THRESHOLD]integerValue]:30;
        self.flatten = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FLATTEN]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FLATTEN]boolValue]:NO;
        self.blur = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_GAUSSIAN]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_GAUSSIAN]integerValue]:1;
        self.saveInverse = options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_INVERSE]?
        [options[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_INVERSE]integerValue]:1;
    }
}
-(void)saveMask{
    if(!self.paintMask)
        return;
    
    if(!self.mask)
        [self createMap];
    
    if(self.mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_THRESHOLD])
        self.mask.jsonDictionary[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS] = [self jsonForNewThresholdMask];
    
    int * copy = [self processedMask];
    
    NSInteger sizePic = self.stack.numberOfPixels;
    UInt16 * sBit = (UInt16 *)calloc(sizePic, sizeof(UInt16));
    for (NSInteger i = 0; i < sizePic; i++)
        sBit[i] = (UInt16)copy[i];//if(copy[i] > 0)sBit[i]--;
    
    self.mask.parent = self.stack;
    [self.mask saveFileWithBuffer:sBit];
    
    if(self.saveInverse == YES){
        self.inv = [[IMCPixelClassification alloc]init];
        self.inv.parent = self.mask.parent;
        [self configureNewMask:self.inv];
        self.inv.jsonDictionary[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS] = [self jsonForNewThresholdMask];
        
        self.inv.itemName = [@"inv_" stringByAppendingString:self.mask.itemHash];
        self.inv.itemSubName = [self.label stringByAppendingString:@"_inv"];
        
        
        UInt16 * iBit = (UInt16 *)calloc(sizePic, sizeof(UInt16));
        for (NSInteger i = 0; i < sizePic; i++)
            iBit[i] = (UInt16)copy[i] != 0?0:1;
        [self.inv saveFileWithBuffer:iBit];
        if(iBit)
            free(iBit);
    }

    
    if(sBit)
        free(sBit);
    if(copy)
        free(copy);
}

-(CGImageRef)channelImage{
    
    if(self.channelIndex == NSNotFound)
        return NULL;
    NSImage *image = [IMCImageGenerator imageForImageStacks:@[self.stack].mutableCopy
                                                    indexes:@[[NSNumber numberWithInteger:self.channelIndex]]
                                           withColoringType:0
                                               customColors:@[[NSColor whiteColor]]
                                          minNumberOfColors:1
                                                      width:self.stack.width
                                                     height:self.stack.height
                                             withTransforms:NO
                                                      blend:kCGBlendModeScreen
                                                   andMasks:nil
                                            andComputations:nil
                                                 maskOption:MASK_NO_BORDERS
                                                   maskType:MASK_ALL_CELL
                                            maskSingleColor:0
                                            isAlignmentPair:NO
                                                brightField:NO];
    
    if(self.blur > 1)
        image = [image gaussianBlurred:(unsigned)self.blur];
    
    if(self.framerIndex > 0){
        CGImageRef ref = image.CGImage;
        NSImage *framerImage = [IMCImageGenerator imageForImageStacks:@[self.stack].mutableCopy
                                                        indexes:@[[NSNumber numberWithInteger:self.framerIndex]]
                                               withColoringType:0
                                                   customColors:@[[NSColor whiteColor]]
                                              minNumberOfColors:1
                                                          width:self.stack.width
                                                         height:self.stack.height
                                                 withTransforms:NO
                                                          blend:kCGBlendModeScreen
                                                       andMasks:nil
                                                andComputations:nil
                                                     maskOption:MASK_NO_BORDERS
                                                       maskType:MASK_ALL_CELL
                                                maskSingleColor:0
                                                isAlignmentPair:NO
                                                    brightField:NO];
        
        if(self.blur > 1)
            framerImage = [framerImage gaussianBlurred:(unsigned)self.blur];
        
        CGImageRef framer = framerImage.CGImage;
        
        UInt8 *refData = [IMCImageGenerator bufferForImageRef:ref];
        UInt8 *framerRefData = [IMCImageGenerator bufferForImageRef:framer];
        
        NSInteger length = self.stack.numberOfPixels * 4;
        UInt8 *newImageBuffer = (UInt8 *)malloc(length/4 * sizeof(UInt8));
        
        for (NSInteger i = 0; i < length; i+=4)
            newImageBuffer[i/4] = (UInt8)((NSInteger)refData[i] * ABS(framerRefData[i] - 255)/255);
        
        ref = [IMCImageGenerator whiteImageFromCArrayOfValues:newImageBuffer width:self.stack.width height:self.stack.height];
        image = [[NSImage alloc]initWithCGImage:ref size:self.stack.size];
    }
    
    
    
    return image.CGImage;
}
-(int *)processedMask{
    
    int * copy = [IMCMasks produceIDedMask:self.paintMask width:self.stack.width height:self.stack.height destroyOrigin:NO];
    
    if(self.flatten)
        [IMCMasks flattenMask:copy width:self.stack.width height:self.stack.height];
    
    return copy;
}
-(void)generateBinaryMask{
    
    CGImageRef ref = [self channelImage];
//    CFDataRef refData = CGDataProviderCopyData(CGImageGetDataProvider(ref));
//    NSInteger sizeBuff = CFDataGetLength(refData);
    
    const UInt8 * buffer = [IMCImageGenerator bufferForImageRef:ref];//CFDataGetBytePtr(refData);
    NSInteger sizeBuff = self.stack.numberOfPixels * 4;
    
    int * aMask = (int *)calloc(self.stack.numberOfPixels, sizeof(int));

    for (NSInteger i = 0; i < sizeBuff; i+= 4)//Start in one because I have ARGB
        if(buffer[i] >= self.thresholdValue)
            aMask[i/4] = 1;
        else
            aMask[i/4] = 0;
    
    if(self.paintMask != NULL)
        free(self.paintMask);
    self.paintMask = aMask;
    if(ref)
        CFRelease(ref);
}
-(void)dealloc{
    if(self.paintMask)
        free(self.paintMask);
}

@end
