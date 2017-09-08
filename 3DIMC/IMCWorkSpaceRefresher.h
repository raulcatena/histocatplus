//
//  IMCWorkSpaceRefresher.h
//  3DIMC
//
//  Created by Raul Catena on 2/17/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCWorkSpace;
@class IMCImageStack;

@interface IMCWorkSpaceRefresher : NSObject

@property (nonatomic, weak) IMCWorkSpace * parent;

-(void)calculateMemory;

-(void)refresh;

-(void)refreshBlend;

//-(void)scaleAndLegendChannels;

-(void)intensityLegend;

-(void)refreshTiles;

-(void)refreshFromImageArray:(NSMutableArray *)array;

-(void)scaleAndLegendChannelsTiles:(NSArray *)involvedStacks;

-(void)changedPanelScrollingType:(NSPopUpButton *)sender;

-(void)updateForWithStack:(IMCImageStack *)stack;

-(void)refreshRControls;

-(MaskType)maskType;

-(void)alignSelected;

@end
