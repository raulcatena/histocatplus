//
//  IMCCellDataImport.h
//  3DIMC
//
//  Created by Raul Catena on 1/31/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CellTableCoordinate_X,
    CellTableCoordinate_Y,
    CellTableCoordinate_Z,
    CellTableCoordinate_bh_1,
    CellTableCoordinate_bh_2,
    CellTableCoordinate_bh_3
} CellTableCoordinate;

@interface IMCCellDataImport : NSObject

-(BOOL)loadDataFromFile:(NSString *)path;
-(float *)valuesForChannel:(NSInteger)index;
-(float *)valuesForChannelWithName:(NSString *)name;
-(float *)coordinates:(CellTableCoordinate)coordinate;

@property (nonatomic, readonly) NSArray *channelNames;

@end
