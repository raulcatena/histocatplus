//
//  IMCChannelSettingsDelegate.h
//  3DIMC
//
//  Created by Raul Catena on 1/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMCChannelSettings.h"

@protocol CustomChannelsTableController <NSObject>

//-(NSInteger)numberOfCells;
-(NSInteger)typeOfColoring;
-(void)didChangeChannel:(NSDictionary *)channelSettings;
-(NSTableView *)whichTableView;
-(NSArray *)channelsForCell;
-(NSArray *)indexesForCell;

@end

@interface IMCChannelSettingsDelegate : NSObject<ChannelConfCell, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) id<CustomChannelsTableController>delegate;
@property (nonatomic, strong) NSMutableArray *settingsJsonArray;
-(NSArray *)collectColors;

-(id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
