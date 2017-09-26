//
//  IMCLoader.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMCFileWrapper.h"

@class IMCPixelClassification;
@class IMCComputationOnMask;
@class IMCPixelTraining;
@class IMCMaskTraining;
@class IMCPixelMap;
@class IMCImageStack;
@class IMC3DMask;

@protocol DataCoordinator <NSObject>

-(NSURL *)fileURL;

@end


@interface IMCLoader : NSObject

@property (nonatomic, strong) NSMutableDictionary *jsonDescription;
@property (nonatomic, readonly) NSMutableDictionary *filesJSONDictionary;
@property (nonatomic, strong) NSMutableArray * inOrderImageWrappers;
@property (nonatomic, readonly) NSMutableArray *inOrderComputations;
@property (nonatomic, weak) id<DataCoordinator>delegate;
@property (nonatomic, copy) NSString *treeSearch;

@property (nonatomic, copy) NSString *selectedRectString;
@property (nonatomic, copy) NSString *zoom;
@property (nonatomic, copy) NSString *position;
@property (nonatomic, copy) NSString *rotation;

-(void)openImagesFromURL:(NSArray<NSURL *>*)url;
-(void)tryMasksFromURL:(NSURL *)url;
+(BOOL)validFile:(NSString *)path;
+(NSArray *)filesInDirectory:(NSURL *)directoryURL;

-(NSArray<IMCFileWrapper *> *)fileWrappers;
-(NSArray<IMCPixelTraining *> *)pixelTrainings;
-(NSArray<IMCPixelClassification *> *)masks;
-(NSArray<IMCComputationOnMask *> *)computations;
-(NSArray<IMCMaskTraining *> *)maskTrainings;
-(NSArray<IMCPixelMap *> *)pixelMaps;
-(NSArray<IMC3DMask *> *)threeDNodes;

-(void)updateFileWrappers;
-(void)removeFileWrapper:(IMCFileWrapper *)wrapper;

-(void)updateOrderedImageList;

-(NSString *)filePath;
-(NSString *)workingDirectoryPath;
-(void)checkAndCreateWorkingDirectory;

//Internal inspection of images
-(NSInteger)maxWidth;
-(NSInteger)maxChannels;
-(NSInteger)maxChannelsComputations;

//Naming
-(void)giveNameToNode:(IMCNodeWrapper *)node inGroup:(NSArray *)group;

//Metadata
-(NSMutableDictionary *)metadata;
-(NSMutableDictionary *)metadataForImageStack:(IMCImageStack *)stack;

//Metrics
-(NSMutableArray *)metrics;

//Comp matrix
-(NSString *)compMatrix;

//3D
-(void)add3DNode:(IMC3DMask *)mask3d;


@end
