//
//  IMCPixelClassification.m
//  3DIMC
//
//  Created by Raul Catena on 2/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelClassification.h"
#import "IMCMasks.h"
#import "IMCImageGenerator.h"
#import "IMCPixelMap.h"
#import "IMCComputationOnMask.h"
#import "NSMutableArrayAdditions.h"
#import "IMCFileExporter.h"

@interface IMCPixelClassification(){
    CGImageRef saveRef;
    NSInteger lastOption;
    MaskType lastType;
    NSInteger segmentsCalculated;
}

@end

@implementation IMCPixelClassification

-(IMCImageStack *)imageStack{
    return (IMCImageStack *)self.parent;
}

-(void)setParent:(IMCNodeWrapper *)parent{
    if(!self.parent && parent){
        if(!parent.jsonDictionary[JSON_DICT_PIXEL_MASKS])
            parent.jsonDictionary[JSON_DICT_PIXEL_MASKS] = @[].mutableCopy;
        if(![parent.jsonDictionary[JSON_DICT_PIXEL_MASKS] containsObject:self.jsonDictionary])
            [parent.jsonDictionary[JSON_DICT_PIXEL_MASKS] addObject:self.jsonDictionary];
    }
    [super setParent:parent];
}

-(void)removeChild:(IMCNodeWrapper *)childNode{    
    for (NSMutableDictionary *trainJson in [self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS]copy])
        if(childNode.jsonDictionary == trainJson){
            [self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS]removeObject:trainJson];
            NSFileManager *man = [NSFileManager defaultManager];
            NSError *error;
            NSLog(@"%@", childNode.absolutePath);
            if([man fileExistsAtPath:childNode.absolutePath])
                [man removeItemAtPath:childNode.absolutePath error:NULL];
            
            if([[NSFileManager defaultManager]fileExistsAtPath:childNode.secondAbsolutePath])
                [[NSFileManager defaultManager]removeItemAtPath:childNode.secondAbsolutePath error:NULL];
            childNode.parent = nil;
            if(error)
                NSLog(@"Error %@", error);
        }
}
-(NSString *)label{
    return self.imageStack.itemName;
}
-(IMCPixelMap *)whichMap{
    for (IMCPixelMap *map in self.imageStack.pixelMaps)
        if(map.itemHash == self.whichMapHash)
            return map;
    return nil;
}
-(NSString *)whichMapHash{
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_WHICH_MAP];
}

-(NSMutableArray *)computationNodes{
    return [self.children filterClass:NSStringFromClass([IMCComputationOnMask class])].mutableCopy;
}
-(void)setJsonDictionary:(NSMutableDictionary *)jsonDictionary{
   [super setJsonDictionary:jsonDictionary];
   [self initComputations];
}

#pragma mark Mask Relations

-(void)initComputations{
   if(!_computationNodes)_computationNodes = @[].mutableCopy;
   for (NSMutableDictionary *trainJson in self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS]) {
          BOOL found = NO;
          for (IMCComputationOnMask *comp in _computationNodes) {
                 if(comp.jsonDictionary == trainJson)found = YES;
             }
         if(found == NO){
                 IMCComputationOnMask *train = [[IMCComputationOnMask alloc]init];
                 train.parent = self;
                 train.jsonDictionary = trainJson;
                 [_computationNodes addObject:train];
             }
      }
}

#pragma mark load and deliver masks

-(void)loadLayerDataWithBlock:(void (^)(void))block{
    if(![self canLoad])return;
    
    dispatch_async(dispatch_queue_create("load_mask", NULL), ^{
        [self loadMask];
        [self loadNuclearMask];
        [super loadLayerDataWithBlock:block];
    });
}

-(void)unLoadLayerDataWithBlock:(void (^)(void))block{
    if(self.mask)
        free(self.mask);
    _mask = NULL;
    for (IMCComputationOnMask *comp in self.computationNodes)
        [comp unLoadLayerDataWithBlock:nil];
    [super unLoadLayerDataWithBlock:block];
}

-(BOOL)loadMask{
    NSString *file = [[self.fileWrapper.pathMainDoc stringByDeletingLastPathComponent]stringByAppendingString:self.jsonDictionary[JSON_DICT_ITEM_RELPATH]];
    if([[NSFileManager defaultManager]fileExistsAtPath:file]){
        if(self.mask)
            free(self.mask);
        _mask = [IMCMasks maskFromFile:[NSURL fileURLWithPath:file] forImageStack:self.imageStack];
        return YES;
    }
    return NO;
}

-(BOOL)loadNuclearMask{
    if(!self.secondRelativePath)
        self.secondRelativePath =
        [self.relativePath stringByReplacingOccurrencesOfString:@"mask_cells" withString:@"mask_nuclei"];
      
    if([[NSFileManager defaultManager]fileExistsAtPath:self.secondAbsolutePath] && ![self.relativePath isEqualToString:self.secondRelativePath]){
        
        self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DUAL] = @YES;
        if(_mask){
            int * nucs = [IMCMasks maskFromFile:[NSURL fileURLWithPath:self.secondAbsolutePath] forImageStack:self.imageStack];
            if(nucs){
                NSInteger size = self.imageStack.numberOfPixels;
                for (NSInteger i = 0; i < size; i++)
                    if(nucs[i] > 0)
                        if (_mask[i] > 0)
                            _mask[i] = -_mask[i];
            }
        }
        return YES;
    }
    
   return NO;
}

-(CGImageRef)coloredMask:(NSInteger)option maskType:(MaskType)maskType singleColor:(NSColor *)color{//0 borders 1 Normal Mask Mask wo border 3 1 color border
    if(!self.mask)return nil;
    if(option == lastOption && lastType == maskType)
        return saveRef;
    else
       if(saveRef){
          CFRelease(saveRef);
          saveRef = NULL;
       }
   lastOption = option;
   lastType = maskType;
   int * copy = copyMask(self.mask, (int)self.imageStack.width, (int)self.imageStack.height);

   NSInteger pix = self.imageStack.numberOfPixels;
   for (NSInteger i = 0; i < pix; i++) {
          if(maskType == MASK_NUC)
                 copy[i] = abs(MIN(0, copy[i]));
         else if(maskType == MASK_CYT)
                 copy[i] = MAX(0, copy[i]);
         else if(maskType != MASK_NUC_PLUS_CYT)
                 copy[i] = abs(copy[i]);
      }

   if(option == 0 || option == 3)
       bordersOnlyMask(copy, self.imageStack.width, self.imageStack.height);
   if(option == 2)
       noBordersMask(copy, self.imageStack.width, self.imageStack.height);
    
   saveRef = [IMCImageGenerator colorMask:copy
                           numberOfColors:option < 3?20:1
                              singleColor:option == 3?color:nil
                                    width:self.imageStack.width
                                   height:self.imageStack.height];
   free(copy);

   return saveRef;
}

#pragma mark add nuclear

-(void)getNuclearMaskAtURL:(NSURL *)url{
    
       NSFileManager *manager = [NSFileManager defaultManager];
   
       NSString *workingCopyFullPath = [[self.fileWrapper workingFolder]stringByAppendingPathComponent:url.lastPathComponent];
       NSString *workingCopyRel = [[self.fileWrapper workingFolderRealative]stringByAppendingPathComponent:url.lastPathComponent];
   
       [self.fileWrapper checkAndCreateWorkingFolder];
   
       if(![manager fileExistsAtPath:workingCopyFullPath]){
          NSError *error;
          [manager copyItemAtURL:url toURL:[NSURL fileURLWithPath:workingCopyFullPath] error:&error];
          if(error)NSLog(@"%@", error);
       }
   
       //[self.fileWrapper.workingFolder stringByAppendingPathComponent:url.lastPathComponent];
       self.secondRelativePath = workingCopyRel;
       self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DUAL] = @YES;
   }

#pragma mark add spatial features from Cell Profile

-(void)addFeaturesFromCellProfiler:(NSURL *)url{
       NSMutableDictionary *dict = @{
                            JSON_DICT_ITEM_RELPATH: url.path,
                            JSON_DICT_ITEM_HASH: [IMCUtils randomStringOfLength:30]
                            }.mutableCopy;
       //[[self computations]addObject:dict];
       IMCComputationOnMask *comp = [[IMCComputationOnMask alloc]init];
       comp.jsonDictionary = dict;
       comp.parent = self;
       [comp addFeaturesFromCellProfiler:url];
   }

-(void)extractDataForMask:(NSIndexSet *)computations processedData:(BOOL)rawOrProcessedData{
    NSMutableDictionary *dict = @{
                    JSON_DICT_ITEM_HASH: [IMCUtils randomStringOfLength:30]
                            }.mutableCopy;
    [[self computations]addObject:dict];
    IMCComputationOnMask *comp = [[IMCComputationOnMask alloc]init];
    comp.jsonDictionary = dict;
    comp.parent = self;
    //comp.isLoaded = YES;
    [comp extractDataForMask:computations processedData:rawOrProcessedData];
}

-(NSMutableArray *)computations{
    if(!self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS])
       self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS] = @[].mutableCopy;
    return self.jsonDictionary[JSON_DICT_PIXEL_MASK_COMPUTATIONS];
}
-(BOOL)isCellMask{
    return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_CELL]boolValue];
}
-(BOOL)isNuclear{
    return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_NUCLEAR]boolValue];
}
-(BOOL)isDual{
    return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DUAL]boolValue];
}
-(BOOL)isDesignated{
    return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DESIGNATED]boolValue];
}
-(BOOL)isPainted{
   return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_PAINTED]boolValue];
}
-(BOOL)isThreshold{
   return [self.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_THRESHOLD]boolValue];
}
-(NSMutableDictionary *)thresholdSettings{
   return self.jsonDictionary[JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS];
}

-(instancetype)initWithPixelMask:(int *)maskBuffer dictionary:(NSDictionary *)dictionary andParent:(IMCImageStack *)stack{
       self = [self init];
       if(self){
               //Create jsonDictionary and add it to jsondict of stack
               //Create image and save it
               //Create a training hash
    }
       return self;
   }

-(NSInteger)numberOfSegments{
    if(segmentsCalculated == 0 && self.mask){
        NSInteger pixels = self.imageStack.numberOfPixels;
        for (NSInteger i = 0; i < pixels; i++) {
            if(self.mask[i] > segmentsCalculated)
                segmentsCalculated = self.mask[i];
        }
    }
    return segmentsCalculated;
}

-(NSUInteger)usedMegaBytes{
    if(!_mask)
        return 0;
    return self.imageStack.numberOfPixels * sizeof(int)/pow(2.0f, 20.0f);
}

-(void)saveFileWith32IntBuffer:(int *)buffer length:(NSInteger)length{
    NSData *data = [NSData dataWithBytes:buffer length:length * sizeof(int)];
    if(!self.relativePath)
        self.relativePath = [self.workingFolderRealative stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m32", self.itemHash]];
    [self.fileWrapper checkAndCreateWorkingFolder];
    [data writeToFile:self.absolutePath options:NSDataWritingAtomic error:NULL];
}

-(void)saveFileWithBuffer:(void *)buffer bits:(size_t)bits{
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CFDataRef dataRef = CFDataCreate(NULL, buffer, self.imageStack.numberOfPixels * 2);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(dataRef);
    
    CGBitmapInfo bmInfo = bits == 16 ? kCGBitmapByteOrder16Little : kCGBitmapByteOrder32Little;

    CGImageRef imageRet = CGImageCreate(self.imageStack.width, self.imageStack.height, bits, bits, self.imageStack.width * bits/8, colorspace, bmInfo, provider, NULL, true, kCGRenderingIntentDefault);
    
    if(!self.relativePath)
        self.relativePath = [self.workingFolderRealative stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.tiff", self.itemHash]];
    
    [self.imageStack.fileWrapper checkAndCreateWorkingFolder];
    
    [IMCFileExporter writeArrayOfRefImages:@[(__bridge_transfer id)imageRet] withTitles:@[@"mask"] atPath:self.absolutePath in16bits:YES];
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    CFRelease(dataRef);
}

-(void)dealloc{
   if(self.mask)
       free(self.mask);
   if(saveRef)
       CFRelease(saveRef);
}

@end
