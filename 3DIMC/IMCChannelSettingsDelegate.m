//
//  IMCChannelSettingsDelegate.m
//  3DIMC
//
//  Created by Raul Catena on 1/22/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCChannelSettingsDelegate.h"

@interface IMCChannelSettingsDelegate()
@property (nonatomic, strong) NSTableView *whichTableView;
@end

@implementation IMCChannelSettingsDelegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.delegate indexesForCell].count;
}

-(id)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
    
    IMCChannelSettings *infoView = [tableView makeViewWithIdentifier:@"ChannelSettings" owner:self];

    infoView.channels = [self.delegate channelsForCell];
    infoView.delegate = self;
    NSInteger channelIndex = [[self.delegate indexesForCell][row]integerValue];
    if(channelIndex < self.settingsJsonArray.count)
        infoView.settingsDictionary = [self.settingsJsonArray objectAtIndex:channelIndex];
    infoView.backgroundStyle = row%2 == 0?NSBackgroundStyleDark:NSBackgroundStyleLight;
    [infoView setTag:channelIndex];
    infoView.localIndex = row;
    
    return infoView;
}

-(NSArray *)collectColors{
    NSMutableArray *array = @[].mutableCopy;
    NSTableColumn *column = [[self.delegate whichTableView]tableColumnWithIdentifier:@"col"];
    
    if(!self.whichTableView)
        self.whichTableView = [self.delegate whichTableView];
        
    for (NSInteger i = 0; i < [self.delegate indexesForCell].count; i++) {
        IMCChannelSettings *cell = [self tableView:self.whichTableView viewForTableColumn:column row:i];
        if(cell)
            [array addObject:cell.color.color];
    }
    return array;
}

#pragma mark Channel Cell Delegate

-(void)madeChannelConfChanges{
    [[self delegate]didChangeChannel:nil];
}

-(NSInteger)numberOfChannels{
    return [self.delegate indexesForCell].count;
}

-(NSInteger)typeOfColoring{
    return [self.delegate typeOfColoring];
}

-(void)changed:(NSInteger)oldChannel for:(NSInteger)newChannel{
    [self.delegate changed:oldChannel for:newChannel];
}

@end
