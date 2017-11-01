//
//  IMCFileWrapper.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCFileWrapper.h"
#import "IMC_TxtLoader.h"
#import "IMC_BIMCLoader.h"
#import "IMC_MCDLoader.h"
#import "IMC_TIFFLoader.h"
#import "IMC_MatlabLoader.h"
#import "IMCFileExporter.h"

//TODO. Generate absolute path from relative and data coordinator in case the folder has been moved

@implementation IMCFileWrapper


-(NSString *)itemName{
    NSString *prefix = @"";
    if(self.hasChanges)prefix = @"Unsaved * ";
    if(self.hasTIFFBackstore == YES)prefix = [prefix stringByAppendingString:@"TIFF*"];
    
    return [prefix stringByAppendingString:self.fileName?self.fileName:@""];
}
-(NSString *)itemSubName{
    return self.relativePath;
}

#pragma mark paths

-(void)loadFileWithBlock:(void(^)())block{
    if(![self isLoaded]){
        dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
        dispatch_async(queue, ^{
            [self loadLayerDataWithBlock:block];
        });
    }
}
-(void)loadOrUnloadFileWithBlock:(void(^)())block{
    if(![self isLoaded]){
        dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
        dispatch_async(queue, ^{
            [self loadLayerDataWithBlock:block];
        });
    }else{
        [self unLoadLayerDataWithBlock:block];
    }
}

-(NSString *)baseDirectoryPath{
    return self.pathMainDoc.stringByDeletingLastPathComponent;
}

-(NSString *)backStoreTIFFPath{
    return [self.absolutePath.stringByDeletingPathExtension stringByAppendingString:@".tiff"];
}

-(NSString *)workingFolder{
    NSString *relPath = [[self relativePath]stringByDeletingPathExtension];
    NSString *docPath = [self.pathMainDoc stringByDeletingLastPathComponent];
    return [[docPath stringByAppendingString:relPath] stringByAppendingString:@"_wd"];
}

-(NSString *)workingFolderRealative{
    NSString *relPath = [[self relativePath]stringByDeletingPathExtension];
    return [relPath stringByAppendingString:@"_wd"];
}

-(void)checkAndCreateWorkingFolder{
    [General checkAndCreateDirectory:[self workingFolder]];
}

#pragma mark more

-(BOOL)hasTIFFBackstore{
    NSFileManager *man = [NSFileManager defaultManager];
    return [man fileExistsAtPath:[self backStoreTIFFPath]];
}

-(NSArray *)allStacks{
    NSMutableArray *arr = @[].mutableCopy;
    for (IMCPanoramaWrapper *pan in self.children)
        for(IMCImageStack *stck in pan.children)
            [arr addObject:stck];
    return [NSArray arrayWithArray:arr];
}

-(void)saveBIMCAtPath:(NSString *)path{
    BOOL success = [IMC_BIMCLoader saveBIMCdata:(IMCImageStack *)self.children.firstObject.children.firstObject toPath:path];
    self.hasChanges = !success;
}
-(void)saveTIFFAtPath:(NSString *)path{
    BOOL isLoaded = self.isLoaded;
    if(!isLoaded)
        [self loadFileWithBlock:nil];
    while (!self.isLoaded);
    [IMCFileExporter saveMultipageTiffAllChannels:(IMCImageStack *)self.children.firstObject.children.firstObject path:path];
    if(!isLoaded)
        [self unLoadLayerDataWithBlock:nil];
    self.hasChanges = NO;
}
-(void)save{
    if([self hasTIFFBackstore]){
        NSLog(@"There is backstore");
        [self saveTIFFAtPath:[self backStoreTIFFPath]];
        return;
    }
    if([self.fileType isEqualToString:EXTENSION_BIMC])[self saveBIMCAtPath:self.absolutePath];
    if([self.fileType hasPrefix:EXTENSION_TIFF_PREFIX])[self saveTIFFAtPath:self.absolutePath];
}


-(NSMutableArray *)containers{
    if(![self.jsonDictionary valueForKey:JSON_DICT_FILE_CONTAINERS])
        [self.jsonDictionary setValue:@[].mutableCopy forKey:JSON_DICT_FILE_CONTAINERS];
    
    return [self.jsonDictionary valueForKey:JSON_DICT_FILE_CONTAINERS];
}

#pragma mark loading

-(BOOL)isSoftLoaded{
    return [[self.jsonDictionary valueForKey:JSON_DICT_FILE_IS_SOFT_LOADED]boolValue];
}

-(void)populateJsonDictForSingleImageFile:(NSString *)path data:(NSData *)data success:(BOOL *)success{
    IMCImageStack * imageStack;
    if (self.children.count == 0) {
        //Suppose TXT has only 1 posible image. This condition avoid redoing dictionary.
        //TODO. Dict reparison function
        NSMutableArray *containers = [self containers];
        
        NSMutableDictionary *spContainer = [containers firstObject];
        if(!spContainer){
            spContainer = @{JSON_DICT_CONT_PANORAMA_NAME:self.fileName}.mutableCopy;
            [containers addObject:spContainer];
        }
        
        NSMutableArray *images = [spContainer valueForKey:JSON_DICT_CONT_PANORAMA_IMAGES];
        if(!images){
            images = @[@{JSON_DICT_IMAGE_NAME:self.fileName}.mutableCopy].mutableCopy;
            [spContainer setValue:images forKey:JSON_DICT_CONT_PANORAMA_IMAGES];
        }
        
        IMCPanoramaWrapper *panWrap = [[IMCPanoramaWrapper alloc]init];
        panWrap.jsonDictionary = containers.firstObject;
        panWrap.parent = self;
        
        imageStack = [[IMCImageStack alloc]init];
        imageStack.parent = panWrap;
        imageStack.jsonDictionary = images.firstObject;
    }
    else
        imageStack = (IMCImageStack *)self.children.firstObject.children.firstObject;
    
    [self loadSingleFiler:imageStack data:data path:path success:success];
}

-(void)loadSingleFiler:(IMCImageStack *)imageStack data:(NSData *)data path:(NSString *)path success:(BOOL *)success{
    
    if([path.pathExtension isEqualToString:EXTENSION_TXT])
        *success = [IMC_TxtLoader loadTXTData:data toIMCImageStack:imageStack];
    
    if([path.pathExtension isEqualToString:EXTENSION_BIMC])
        *success = [IMC_BIMCLoader loadBIMCdata:data toIMCImageStack:imageStack];
    
    if([path.pathExtension isEqualToString:EXTENSION_TIFF]
       || [path.pathExtension isEqualToString:EXTENSION_TIF])
        *success = [IMC_TIFFLoader loadTIFFData:data toIMCImageStack:imageStack];
    
    if([path.pathExtension isEqualToString:EXTENSION_JPEG]
       || [path.pathExtension isEqualToString:EXTENSION_JPG]
       || [path.pathExtension isEqualToString:EXTENSION_BMP]
       || [path.pathExtension isEqualToString:EXTENSION_PNG])
        *success = [IMC_TIFFLoader loadNonTIFFData:data toIMCImageStack:imageStack];
    
    if([path.pathExtension isEqualToString:EXTENSION_M32])
        *success = [IMC_MatlabLoader loadMatDataETHZ:data toIMCImageStack:imageStack];

}

-(void)populateJsonDictForMCDImagesFile:(NSString *)path data:(NSData *)data success:(BOOL *)success{
    //if (self.children.count != 1) {
        *success = [IMC_MCDLoader loadMCD:data toIMCFileWrapper:self];
    //}
}
-(void)softLoad{
    NSMutableArray *containers = [self containers];
    for (NSMutableDictionary *spContainer in containers) {
        NSMutableArray *images = [spContainer valueForKey:JSON_DICT_CONT_PANORAMA_IMAGES];
        
        IMCPanoramaWrapper *panWrap = [[IMCPanoramaWrapper alloc]init];
        panWrap.jsonDictionary = spContainer;
        panWrap.parent = self;
        
        IMCImageStack * imageStack = [[IMCImageStack alloc]init];
        imageStack.parent = panWrap;
        imageStack.jsonDictionary = images.firstObject;
    }
    [self.jsonDictionary setValue:[NSNumber numberWithBool:YES] forKey:JSON_DICT_FILE_IS_SOFT_LOADED];
}

-(void)loadLayerDataWithBlock:(void (^)())block{
    
    dispatch_queue_t aQ = dispatch_queue_create("aQQ", NULL);
    dispatch_async(aQ, ^{
        if([self isMemberOfClass:NSClassFromString(@"IMCPixelMap")]){
            [super loadLayerDataWithBlock:block];
            return;
        }
        NSString *path = [[self.pathMainDoc stringByDeletingLastPathComponent]stringByAppendingString:[self relativePath]];
        if([self hasTIFFBackstore])
            path = [self backStoreTIFFPath];
        
        NSData *data = [NSData dataWithContentsOfFile:path];
        BOOL success = NO;
        if(data){
            if([path.pathExtension isEqualToString:EXTENSION_TXT]
               || [path.pathExtension isEqualToString:EXTENSION_BIMC]
               || [path.pathExtension isEqualToString:EXTENSION_TIFF]
               || [path.pathExtension isEqualToString:EXTENSION_TIF]
               || [path.pathExtension isEqualToString:EXTENSION_MAT]
               || [path.pathExtension isEqualToString:EXTENSION_JPG]
               || [path.pathExtension isEqualToString:EXTENSION_JPEG]
               || [path.pathExtension isEqualToString:EXTENSION_BMP]
               || [path.pathExtension isEqualToString:EXTENSION_PNG]){
                [self populateJsonDictForSingleImageFile:path data:data success:&success];
            }
            if([path.pathExtension isEqualToString:EXTENSION_MCD]){
                [self populateJsonDictForMCDImagesFile:path data:data success:&success];
            }
            
        }
        if(!success)
            dispatch_async(dispatch_get_main_queue(), ^{
                [General runAlertModalWithMessage:@"Problem loading file"];
            });
        else
            [super loadLayerDataWithBlock:block];
    });
}
-(void)unLoadLayerDataWithBlock:(void (^)())block{
    self.isLoaded = NO;
    for (IMCPanoramaWrapper *wrap in self.children){
        wrap.isLoaded = NO;
        for (IMCImageStack *stck in self.children)
            [stck unLoadLayerDataWithBlock:nil];
    }
    [super unLoadLayerDataWithBlock:block];
}

@end
