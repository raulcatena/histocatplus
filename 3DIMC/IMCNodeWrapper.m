//
//  IMCNodeWrapper.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"
#import "IMCFileWrapper.h"

@implementation IMCNodeWrapper
@synthesize jsonDictionary = _jsonDictionary;;

-(id)fileWrapper{
    IMCNodeWrapper *node = self;
    while (node.parent) {
        node = node.parent;
    }
    return node;
}

-(NSMutableArray *)children{
    if(!_children)_children = [NSMutableArray array];
    return _children;
}

-(void)setParent:(IMCNodeWrapper *)parent{
    if(!parent){
        if([self.parent.children containsObject:self])
            [self.parent.children removeObject:self];
    }else{
        if(!self.parent.children)
            self.parent.children = @[].mutableCopy;
        if(![parent.children containsObject:self])
            [parent.children addObject:self];
    }
    _parent = parent;
}

-(void)setJsonDictionary:(NSMutableDictionary *)jsonDictionary{
    _jsonDictionary = jsonDictionary;
    [self populateSelfWithDictionary];
}
-(NSMutableDictionary *)jsonDictionary{
    if(!_jsonDictionary)_jsonDictionary = @{}.mutableCopy;
    return _jsonDictionary;
}
//Override in subclasses if necessary
-(NSMutableDictionary *)generateSelfDictionary{
    return nil;
}

-(void)populateSelfWithDictionary{

}
-(void)openIfNecessaryAndPerformBlock:(void(^)(void))block{
    BOOL wasLoaded = self.isLoaded;
    if(!wasLoaded)
        [self loadLayerDataWithBlock:nil];
    while(!self.isLoaded);
    if(block)
        block();
    if(!wasLoaded)
        [self unLoadLayerDataWithBlock:nil];
}
-(void)loadLayerDataWithBlock:(void(^)(void))block;{
    if([self isMemberOfClass:[IMCFileWrapper class]])
        for (IMCNodeWrapper *pan in self.children){
            pan.isLoaded = YES;
            for (IMCNodeWrapper *stk in pan.children)
                stk.isLoaded = YES;
        }

    self.isLoaded = YES;
    if(block)
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block)block();
        });
}
-(void)setIsLoaded:(BOOL)isLoaded{
    _isLoaded = isLoaded;
    if(isLoaded)self.loading = !isLoaded;
}
-(BOOL)canLoad{
    BOOL canLoadResult = (!self.isLoaded && !self.loading);
    if(canLoadResult)
        self.loading = YES;
    return canLoadResult;
}
-(void)unLoadLayerDataWithBlock:(void(^)(void))block;{
    if([self isMemberOfClass:[IMCFileWrapper class]])
        for (IMCNodeWrapper *pan in self.children){
            pan.isLoaded = NO;
            for (IMCNodeWrapper *stk in pan.children)
                stk.isLoaded = NO;
        }
    
    
    self.isLoaded = NO;
    if (block)
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block)block();
        });
}

-(NSString *)itemName{
    return self.jsonDictionary[JSON_DICT_ITEM_NAME];
}
-(void)setItemName:(NSString *)itemName{
    self.jsonDictionary[JSON_DICT_ITEM_NAME] = itemName;
}
-(NSString *)itemSubName{
    return self.jsonDictionary[JSON_DICT_ITEM_SUBNAME];
}
-(void)setItemSubName:(NSString *)itemName{
    self.jsonDictionary[JSON_DICT_ITEM_SUBNAME] = itemName;
}
-(NSString *)itemHash{
    if(!self.jsonDictionary[JSON_DICT_ITEM_HASH])
        self.jsonDictionary[JSON_DICT_ITEM_HASH] = [IMCUtils randomStringOfLength:20];
    return self.jsonDictionary[JSON_DICT_ITEM_HASH];
}
-(void)setItemHash:(NSString *)itemHash{
    self.jsonDictionary[JSON_DICT_ITEM_HASH] = itemHash;
}
-(NSUInteger)usedMegaBytes{
    return 0;
}

#pragma mark file handling

-(NSString *)workingFolder{
    return self.fileWrapper.workingFolder;
}
-(NSString *)workingFolderRealative{
    return self.fileWrapper.workingFolderRealative;
}
-(NSString *)baseDirectoryPath{
    return self.fileWrapper.baseDirectoryPath;
}
-(NSString *)relativePath{
    return self.jsonDictionary[JSON_DICT_ITEM_RELPATH];
}
-(void)setRelativePath:(NSString *)relativePath{
    self.jsonDictionary[JSON_DICT_ITEM_RELPATH] = relativePath;
}
-(NSString *)fileName{
    return [self.jsonDictionary[JSON_DICT_ITEM_RELPATH]lastPathComponent];
}
-(NSString *)absolutePath{
    NSFileManager *man = [NSFileManager defaultManager];
    if([man fileExistsAtPath:[self.jsonDictionary valueForKey:JSON_DICT_ITEM_ABSPATH]]){
        return [self.jsonDictionary valueForKey:JSON_DICT_ITEM_ABSPATH];
    }else
        if(self.relativePath)
            [self.jsonDictionary setValue:[[self baseDirectoryPath]stringByAppendingPathComponent:self.relativePath] forKey:JSON_DICT_ITEM_ABSPATH];
    if([self.jsonDictionary[JSON_DICT_ITEM_ABSPATH] isEqualToString:[self baseDirectoryPath]])
        return nil;
    return [self.jsonDictionary valueForKey:JSON_DICT_ITEM_ABSPATH];
}
-(NSString *)fileType{
    return self.jsonDictionary[JSON_DICT_ITEM_FILETYPE];
}
-(NSString *)secondRelativePath{
    return self.jsonDictionary[JSON_DICT_ITEM_SECOND_RELPATH];
}
-(void)setSecondRelativePath:(NSString *)secondRelativePath{
    self.jsonDictionary[JSON_DICT_ITEM_SECOND_RELPATH] = secondRelativePath;
}
-(NSString *)secondFileName{
    return [self.jsonDictionary[JSON_DICT_ITEM_SECOND_RELPATH]lastPathComponent];
}
-(NSString *)secondAbsolutePath{
    NSFileManager *man = [NSFileManager defaultManager];
    if([man fileExistsAtPath:[self.jsonDictionary valueForKey:JSON_DICT_ITEM_SECOND_ABSPATH]]){
        return [self.jsonDictionary valueForKey:JSON_DICT_ITEM_SECOND_ABSPATH];
    }else
        if(self.secondRelativePath)
            [self.jsonDictionary setValue:[[self baseDirectoryPath]stringByAppendingPathComponent:self.secondRelativePath] forKey:JSON_DICT_ITEM_SECOND_ABSPATH];
    if([self.jsonDictionary[JSON_DICT_ITEM_SECOND_ABSPATH] isEqualToString:[self baseDirectoryPath]])
        return nil;
    return [self.jsonDictionary valueForKey:JSON_DICT_ITEM_SECOND_ABSPATH];
}
-(NSString *)secondFileType{
    return self.jsonDictionary[JSON_DICT_ITEM_SECOND_FILETYPE];
}


@end
