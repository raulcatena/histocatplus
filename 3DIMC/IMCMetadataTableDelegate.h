//
//  IMCMetadataTableDelegate.h
//  3DIMC
//
//  Created by Raul Catena on 6/8/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;
@class IMCLoader;

@protocol MetadataTableDelegate <NSObject>

-(NSArray <IMCImageStack *>*)involvedStacksForMetadata;
-(NSTableView *)metadataTable;
-(IMCLoader *)dataCoordinator;

@end

@interface IMCMetadataTableDelegate : NSObject<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) id<MetadataTableDelegate>delegate;

-(void)rebuildTable;
-(NSArray <IMCImageStack *>*)selectedStacks;

@end
