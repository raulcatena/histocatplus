//
//  IMCFileWrapper.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMCNodeWrapper.h"
#import "IMCLoader.h"

@class IMCLoader;

@interface IMCFileWrapper : IMCNodeWrapper

@property (nonatomic, strong) NSString *fileHash;
@property (nonatomic, strong) NSString *pathMainDoc;
@property (nonatomic, weak) IMCLoader *coordinator;

-(NSMutableArray *)containers;
-(BOOL)isSoftLoaded;
-(void)softLoad;

-(void)checkAndCreateWorkingFolder;
-(void)loadFileWithBlock:(void(^)(void))block;
-(void)loadOrUnloadFileWithBlock:(void(^)(void))block;
-(NSArray *)allStacks;
-(void)save;


@end
