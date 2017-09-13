//
//  IMCLoader.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCLoader.h"
#import "NSData+MD5.h"
#import "NSString+MD5.h"
#import "IMCWorkSpace.h"
#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"
#import "IMCPixelTraining.h"
#import "IMCPixelClassification.h"
#import "IMCComputationOnMask.h"
#import "IMCMaskTraining.h"
#import "IMCPixelMap.h"

@interface IMCLoader()
@property (nonatomic, strong) NSMutableArray *fileWrappersContainer;
@property (nonatomic, readonly) NSMutableArray * inOrderImageHashes;
@property (nonatomic, strong) NSMutableArray *unwrappedPixelTrainings;
@property (nonatomic, strong) NSMutableArray *unwrappedMasks;
@property (nonatomic, strong) NSMutableArray *unwrappedComputations;
@property (nonatomic, strong) NSMutableArray *unwrappedMaskTrainings;
@property (nonatomic, strong) NSMutableArray *unwrappedPixelMaps;
@end

@implementation IMCLoader

-(NSString *)filePath{
    return [[self.delegate fileURL]path];
}

-(NSString *)workingDirectoryPath{
    return [[[self.delegate fileURL]path]stringByDeletingPathExtension];
}

-(void)checkAndCreateWorkingDirectory{
    [General checkAndCreateDirectory:[[[self.delegate fileURL]path]stringByDeletingPathExtension]];
}

//http://iosdevelopertips.com/core-services/create-md5-hash-from-nsstring-nsdata-or-file.html

+(NSArray *)filesInDirectory:(NSURL *)directoryURL{
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:directoryURL.path error:&error];
    return contents;
//    NSArray *contents = [fileManager contentsOfDirectoryAtURL:directoryURL
//                                   includingPropertiesForKeys:@[]
//                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
//                                                        error:nil];
    
//    http://nshipster.com/nsfilemanager/ //RCFLearn
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'png'"];
//    for (NSURL *fileURL in [contents filteredArrayUsingPredicate:predicate]) {
//        // Enumerate each .png file in directory
//    }
   
}

+(BOOL)validFile:(NSString *)path{
    NSArray *validExtensions = @[EXTENSION_TXT, EXTENSION_MCD, EXTENSION_BIMC, EXTENSION_TIFF, EXTENSION_TIF, EXTENSION_MAT, EXTENSION_JPG, EXTENSION_JPEG, EXTENSION_PNG, EXTENSION_BMP];
    NSString *extension = path.pathExtension;
    return ([validExtensions indexOfObject:extension] < validExtensions.count)?YES:NO;
}

#define FILE_SAMPLE_BYTES 20000
+(NSString *)fileSubroutine:(NSString *)path{
    if(![IMCLoader validFile:path])return nil;
    
    NSError *error;

    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    NSData *nsData = [handle readDataOfLength:MIN(FILE_SAMPLE_BYTES, fileSize)];//This way I don't need to read the whole file
    [handle closeFile];
    //NSData *nsData = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&error];
    //NSData *nsData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
    if(error)NSLog(@"Error__ %@", error);
    if (nsData)
        return [nsData MD5];
    return nil;
}

-(void)refreshHashForFile:(NSString *)relativePath{
    NSString *foundHash;
    NSDictionary *foundDictionary;
    for (NSString *hash in [self filesJSONDictionary]) {
        NSDictionary *fileDict = [[self filesJSONDictionary]valueForKey:hash];
        if([[fileDict valueForKey:JSON_DICT_ITEM_RELPATH]isEqualToString:relativePath]){
            foundHash = hash;
            foundDictionary = fileDict;
            break;
        }
    }
    if(foundHash && foundDictionary){
        [[self filesJSONDictionary]removeObjectForKey:foundHash];
        [[self filesJSONDictionary]setValue:foundDictionary forKey:[IMCLoader fileSubroutine:[self fullPathWithRelative:relativePath]]];
    }
}

-(void)refreshHashForHash:(NSString *)testHash{
    NSString *foundHash;
    NSDictionary *foundDictionary;
    for (NSString *hash in [self filesJSONDictionary]) {
        if([hash isEqualToString:testHash]){
            foundHash = hash;
            foundDictionary = [[self filesJSONDictionary]valueForKey:testHash];
            break;
        }
    }
    
    if(foundHash && foundDictionary){
        [[self filesJSONDictionary]removeObjectForKey:testHash];
        [[self filesJSONDictionary]setValue:foundDictionary forKey:[IMCLoader fileSubroutine:[self fullPathWithRelative:[foundDictionary valueForKey:JSON_DICT_ITEM_RELPATH]]]];
    }
}

-(void)setCheckSum:(NSString *)checkSum filePath:(NSString *)path{
    
    NSMutableDictionary *fileDict = [self.filesJSONDictionary valueForKey:checkSum];
    if(!fileDict)fileDict = @{}.mutableCopy;
    [fileDict setValue:path forKey:JSON_DICT_ITEM_ABSPATH];
    [fileDict setValue:[self relativePathOf:path] forKey:JSON_DICT_ITEM_RELPATH];
    [fileDict setValue:[path pathExtension] forKey:JSON_DICT_ITEM_FILETYPE];
    
    [[self.jsonDescription valueForKey:JSON_DICT_FILES]setValue:fileDict forKey:checkSum];
}

-(void)notifyNeedsSubfolder{
       [General runAlertModalWithMessage:@"You can only add images that are located in the same folder or subfolders to the location of the project file. Once files are added. Do not move the files from the location"];
}

-(BOOL)isSubFolderOfDocument:(NSURL *)url{
    NSArray *pathComps = url.pathComponents;
    NSMutableArray *docComps = [self.delegate fileURL].pathComponents.mutableCopy;
    [docComps removeLastObject];
    
    if(pathComps.count < docComps.count){
        [self notifyNeedsSubfolder];
        return NO;
    }
    
    for (NSString *pathCompDoc in docComps) {
        if(![pathCompDoc isEqualToString:[pathComps objectAtIndex:[docComps indexOfObject:pathCompDoc]]]){
            [self notifyNeedsSubfolder];
            return NO;
        }
    }
    return YES;
}

-(NSString *)relativePathOf:(NSString *)subPath{
    NSMutableArray *pathComps = subPath.pathComponents.mutableCopy;
    NSMutableArray *docComps = [self.delegate fileURL].pathComponents.mutableCopy;
    [docComps removeLastObject];
    
    NSMutableString *relativePath = @"".mutableCopy;
    while (pathComps.count > docComps.count) {
        [relativePath insertString:pathComps.lastObject atIndex:0];
        [relativePath insertString:@"/" atIndex:0];
        [pathComps removeLastObject];
    }
    return relativePath;
}
         
 -(NSString *)fullPathWithRelative:(NSString *)relativePath{
     
     NSString *docRoot = [[self.delegate fileURL].path stringByDeletingLastPathComponent];
     return [docRoot stringByAppendingString:relativePath];
 }

-(void)openImagesFromURL:(NSArray<NSURL *> *)urls{////TODO address of int for loading feedback
    if(![self isSubFolderOfDocument:urls.firstObject])return;
    
    NSString *checkSum;
    for (NSURL *url in urls) {
        if([General isDirectory:url]){
            for (NSString *itemUrl in [IMCLoader filesInDirectory:url]) {
                if(![IMCLoader validFile:itemUrl])continue;
                if([General isDirectory:[NSURL fileURLWithPath:itemUrl]]){
                    ////TODO
                    NSLog(@"Is a directory. recursion?");
                    continue;
                }
                NSString *fullPath = [url.path stringByAppendingPathComponent:itemUrl];
                checkSum = [IMCLoader fileSubroutine:fullPath];
                if (checkSum)[self setCheckSum:checkSum filePath:fullPath];
            }
        }else{
            checkSum = [IMCLoader fileSubroutine:url.path];
            if (checkSum)[self setCheckSum:checkSum filePath:url.path];
        }
    }
    [self updateFileWrappers];
    [self updateOrderedImageList];
}
-(void)tryMasksFromURL:(NSURL *)url{
    if([General isDirectory:url]){
        for (NSString *itemUrl in [IMCLoader filesInDirectory:url]) {
            if(![IMCLoader validFile:itemUrl])continue;
            if([General isDirectory:[NSURL fileURLWithPath:itemUrl]])
                continue;
            
            NSString *fullPath = [url.path stringByAppendingPathComponent:itemUrl];
            if([fullPath.pathExtension isEqualToString:EXTENSION_TIFF] || [fullPath.pathExtension isEqualToString:EXTENSION_TIF] || [fullPath.pathExtension isEqualToString:EXTENSION_MAT])
                if([itemUrl rangeOfString:@"mask"].location != NSNotFound)
                    for (IMCImageStack *stack in self.inOrderImageWrappers)
                        if([itemUrl hasPrefix:[stack.itemName stringByDeletingPathExtension]]){
                            NSString *fullPath = [url.path stringByAppendingPathComponent:itemUrl];
                            [stack getMaskAtURL:[NSURL fileURLWithPath:fullPath]];
                        }
        }
    }
}
#pragma mark filewrapper objects
-(void)updateFileWrappers{
    //NSLog(@"%@", self.jsonDescription);
    
    if(!self.fileWrappersContainer)
        self.fileWrappersContainer = @[].mutableCopy;
    
    for (NSString *fileHash in [self filesJSONDictionary]) {
        BOOL foundWrapper = NO;
        for (IMCFileWrapper *wrapper in self.fileWrappersContainer) {
            if([wrapper.fileHash isEqualToString:fileHash]){
                foundWrapper = YES;
                break;
            }
        }
        if (foundWrapper == NO) {
            IMCFileWrapper *wrapperNew = [[IMCFileWrapper alloc]init];
            wrapperNew.coordinator = self;
            wrapperNew.pathMainDoc = [[self.delegate fileURL]path];
            wrapperNew.fileHash = fileHash;
            wrapperNew.jsonDictionary = [self.filesJSONDictionary valueForKey:fileHash];
            [wrapperNew.jsonDictionary removeObjectForKey:JSON_DICT_FILE_IS_LOADED];
            [wrapperNew softLoad];
            [self.fileWrappersContainer addObject:wrapperNew];
        }
    }
}
-(NSArray<IMCFileWrapper *> *)fileWrappers{
    if(!self.treeSearch || self.treeSearch.length == 0)
        return self.fileWrappersContainer;
    NSMutableArray *filtered = @[].mutableCopy;
    for (IMCFileWrapper *wrap in self.fileWrappersContainer) {
        if([wrap.itemName rangeOfString:self.treeSearch].length > 0 ||
           [wrap.itemSubName rangeOfString:self.treeSearch].length > 0)
            [filtered addObject:wrap];
    }
    return filtered;
}

-(void)removeFileWrapper:(IMCFileWrapper *)wrapper{
    [self.fileWrappersContainer removeObject:wrapper];
    [self updateFileWrappers];
    [self updateOrderedImageList];
}

#pragma mark other wrappers
-(BOOL)shouldAddFromSearch:(IMCNodeWrapper *)node{
    
    return ([node.itemName.lowercaseString rangeOfString:self.treeSearch?self.treeSearch.lowercaseString:@""].length > 0 ||
            [node.itemSubName.lowercaseString rangeOfString:self.treeSearch?self.treeSearch.lowercaseString:@""].length > 0 ||
            self.treeSearch.length == 0);
}
-(NSMutableArray *)inOrderImageWrappers{
    if(!self.treeSearch || self.treeSearch.length == 0)
        return _inOrderImageWrappers;
    
    NSMutableArray *filtered = @[].mutableCopy;
    for (IMCImageStack *stack in _inOrderImageWrappers) {
        if([self shouldAddFromSearch:stack])
            [filtered addObject:stack];
    }
    return filtered;
}

-(NSArray <IMCPixelTraining *>*)pixelTrainings{
//    if(!_unwrappedPixelTrainings)
//        _unwrappedPixelTrainings = @[].mutableCopy;

    NSMutableArray *filtered = @[].mutableCopy;
    for(IMCImageStack *stck in _inOrderImageWrappers.copy)
        for (IMCPixelTraining *mask in stck.pixelTrainings)
            if(![filtered containsObject:mask] && [self shouldAddFromSearch:mask])
                [filtered addObject:mask];
    
    return filtered;
}
-(NSArray <IMCPixelClassification *>*)masks{
//    if(!self.unwrappedMasks)
//        self.unwrappedMasks = @[].mutableCopy;
//    [self.unwrappedMasks removeAllObjects];
    
    NSMutableArray *filtered = @[].mutableCopy;
    for(IMCImageStack *stck in _inOrderImageWrappers.copy)
        for (IMCPixelClassification *mask in stck.pixelMasks)
            if(![filtered containsObject:mask] && [self shouldAddFromSearch:mask])
                [filtered addObject:mask];
    
    return filtered;
}
-(NSArray <IMCPixelMap *>*)pixelMaps{
//    if(!self.unwrappedPixelMaps)
//        self.unwrappedPixelMaps = @[].mutableCopy;
//    [self.unwrappedPixelMaps removeAllObjects];
    
    NSMutableArray *filtered = @[].mutableCopy;
    for(IMCImageStack *stck in _inOrderImageWrappers.copy)
        for (IMCPixelMap *mask in stck.pixelMaps)
            if(![filtered containsObject:mask]  && [self shouldAddFromSearch:mask])
                [filtered addObject:mask];
    
    return filtered;
}
-(NSArray <IMCComputationOnMask *>*)computations{
//    if(!self.unwrappedComputations)
//        self.unwrappedComputations = @[].mutableCopy;
//    [self.unwrappedComputations removeAllObjects];
    
    NSMutableArray *filtered = @[].mutableCopy;
    for(IMCPixelClassification *mask in self.masks)
        for(IMCComputationOnMask *comp in mask.computationNodes)
            if(![filtered containsObject:comp] && [self shouldAddFromSearch:comp])
                    [filtered addObject:comp];
    return filtered;
}
-(NSArray <IMCMaskTraining *>*)maskTrainings{
//    if(!self.unwrappedMaskTrainings)
//        self.unwrappedMaskTrainings = @[].mutableCopy;
//    [self.unwrappedMaskTrainings removeAllObjects];
    
    NSMutableArray *filtered = @[].mutableCopy;
    for(IMCComputationOnMask *comp in self.computations)
        for(IMCMaskTraining *train in comp.trainingNodes)
            if(![filtered containsObject:train]  && [self shouldAddFromSearch:train])
                [filtered addObject:train];
    return filtered;
}

#pragma mark dict wrappers for images

//Thin wrapper for images

-(void)updateOrderedImageList{
    NSLog(@"UPDATING LIST");
    
    if(!_inOrderImageWrappers){
        _inOrderImageWrappers = @[].mutableCopy;
        for (NSString *str in self.inOrderImageHashes)
            for (IMCFileWrapper *wrap in self.fileWrappers)
                for (IMCImageStack *stack in wrap.allStacks)
                    if([str isEqualToString:stack.itemHash])
                        [_inOrderImageWrappers addObject:stack];
    }
    for (IMCFileWrapper *wrap in self.fileWrappers)
        for (IMCImageStack *stack in wrap.allStacks)
            if(![_inOrderImageWrappers containsObject:stack])
                [_inOrderImageWrappers addObject:stack];
    
    NSMutableArray *copyOrdered = @[].mutableCopy;
    for (IMCImageStack *stack in _inOrderImageWrappers)
            [copyOrdered addObject:stack.itemHash];
    
    [self.jsonDescription setValue:copyOrdered forKey:JSON_DICT_FILE_ORDER];
}

#pragma mark smart getters

-(NSMutableArray *)inOrderImageHashes{
    if(![self.jsonDescription valueForKey:JSON_DICT_FILE_ORDER])
        [self.jsonDescription setValue:@[].mutableCopy forKey:JSON_DICT_FILE_ORDER];
    return [self.jsonDescription valueForKey:JSON_DICT_FILE_ORDER];
}
-(NSMutableArray *)inOrderComputations{
    NSMutableArray *comps = @[].mutableCopy;
    for (IMCImageStack *stack in self.inOrderImageWrappers)
        for (IMCPixelClassification *mask in stack.pixelMasks)
            for (IMCComputationOnMask *comp in mask.computationNodes)
                [comps addObject:comp];
    return comps;
}

-(NSMutableDictionary *)jsonDescription{
    
    if(!_jsonDescription){
        _jsonDescription = @{}.mutableCopy;
        [_jsonDescription setValue:@{}.mutableCopy forKey:JSON_DICT_FILES];
    }
    return _jsonDescription;
}

#pragma mark inspect loaded files

-(NSInteger)maxWidth{
    NSInteger max = 0;
    for (IMCImageStack *stack in _inOrderImageWrappers) {
        max = MAX(max, MAX(stack.width, stack.height));
    }
    return max;
}
-(NSInteger)maxChannels{
    NSInteger maxChannels = 0;
    for (IMCImageStack *stack in _inOrderImageWrappers) {
        maxChannels = MAX(maxChannels, stack.channels.count);
    }
    return maxChannels;
}
-(NSInteger)maxChannelsComputations{
    NSInteger maxChannels = 0;
    for (IMCComputationOnMask *comp in self.inOrderComputations) {
        maxChannels = MAX(maxChannels, comp.channels.count);
    }
    return maxChannels;
}


-(NSMutableDictionary *)filesJSONDictionary{
    return [self.jsonDescription valueForKey:JSON_DICT_FILES];
}

#pragma mark metadata
-(NSMutableDictionary *)metadata{
    NSMutableDictionary * metadata = self.jsonDescription[JSON_METADATA];
    if(!metadata){
        metadata = @{}.mutableCopy;
        self.jsonDescription[JSON_METADATA] = metadata;
    }
    
    if(!metadata[JSON_METADATA_KEYS])
        metadata[JSON_METADATA_KEYS] = @[].mutableCopy;
    if(!metadata[JSON_METADATA_VALUES_DICT])
        metadata[JSON_METADATA_VALUES_DICT] = @{}.mutableCopy;
    return metadata;
}
-(NSMutableDictionary *)metadataForImageStack:(IMCImageStack *)stack{
    NSMutableDictionary *dictStack = self.metadata[JSON_METADATA_VALUES_DICT][stack.itemHash];
    if(!dictStack){
        dictStack = @{}.mutableCopy;
        self.metadata[JSON_METADATA_VALUES_DICT][stack.itemHash] = dictStack;
    }
    return dictStack;
}

#pragma mark metrics
-(NSMutableArray *)metrics{
    NSMutableArray *metricsRetrieved = self.jsonDescription[JSON_METRICS];
    if(!metricsRetrieved)
        self.jsonDescription[JSON_METRICS] = @[].mutableCopy;
    return metricsRetrieved;
}

#pragma mark 3Dstate

-(void)setSelectedRectString:(NSString *)selectedRectString{
    _jsonDescription[THREE_D_ROI] = selectedRectString;
}
-(NSString *)selectedRectString{
    return _jsonDescription[THREE_D_ROI];
}
-(void)setZoom:(NSString *)zoom{
    _jsonDescription[THREE_D_ZOOM] = zoom;
}
-(NSString *)zoom{
    return _jsonDescription[THREE_D_ZOOM];
}
-(void)setPosition:(NSString *)position{
    _jsonDescription[THREE_D_POS] = position;
}
-(NSString *)position{
    return _jsonDescription[THREE_D_POS];
}
-(void)setRotation:(NSString *)rotation{
    _jsonDescription[THREE_D_ROT] = rotation;
}
-(NSString *)rotation{
    return _jsonDescription[THREE_D_ROT];
}

#pragma mark comp matrix

-(NSString *)compMatrix{
    if(self.jsonDescription[COMP_MATRIX])
        return self.jsonDescription[COMP_MATRIX];
    
    NSError *error;
    NSString *path = [[NSBundle mainBundle]pathForResource:@"201806_spillmat" ofType:@"txt"];
    NSString *matrix = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(error)NSLog(@"Error %@", error.description);
    return matrix;
}


@end
