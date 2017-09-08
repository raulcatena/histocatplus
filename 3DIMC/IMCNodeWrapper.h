//
//  IMCNodeWrapper.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCFileWrapper;

@interface IMCNodeWrapper : NSObject

@property (nonatomic, strong) NSMutableDictionary *jsonDictionary;
@property (nonatomic, strong) NSString *itemHash;
@property (nonatomic, strong) NSString *itemName;
@property (nonatomic, strong) NSString *itemSubName;
@property (nonatomic, weak) IMCNodeWrapper *parent;
@property (nonatomic, strong) NSMutableArray<IMCNodeWrapper *> *children;
@property (nonatomic, readonly) IMCFileWrapper * fileWrapper;
@property (nonatomic, assign) BOOL hasChanges;
@property (nonatomic, assign) BOOL isLoaded;

//File handling
@property (nonatomic, readonly) NSString * workingFolder;
@property (nonatomic, readonly) NSString * workingFolderRealative;
@property (nonatomic, readonly) NSString * baseDirectoryPath;
@property (nonatomic, strong) NSString * relativePath;
@property (nonatomic, readonly) NSString * fileName;
@property (nonatomic, readonly) NSString * absolutePath;
@property (nonatomic, readonly) NSString * fileType;
@property (nonatomic, strong) NSString * secondRelativePath;
@property (nonatomic, readonly) NSString * secondFileName;
@property (nonatomic, readonly) NSString * secondAbsolutePath;
@property (nonatomic, readonly) NSString * secondFileType;


-(NSUInteger)usedMegaBytes;

-(NSMutableDictionary *)generateSelfDictionary;
-(void)populateSelfWithDictionary;
-(void)loadLayerDataWithBlock:(void(^)())block;//To always override
-(void)unLoadLayerDataWithBlock:(void(^)())block;//To always override

@end
