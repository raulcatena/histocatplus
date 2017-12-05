//
//  IMCChannelSettings.m
//  IMCReader
//
//  Created by Raul Catena on 1/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCChannelSettings.h"
#import "IMCImageGenerator.h"

@implementation IMCChannelSettings

-(void)awakeFromNib{
    
}

-(void)setChannels:(NSArray *)channels{
    _channels = channels;
    for (NSString *str in _channels) {//TODO refactor this
        [self.selectChannel addItemWithTitle:@"blah"];
        [[self.selectChannel lastItem]setTitle:str];
    }
}

-(void)setSettingsDictionary:(NSMutableDictionary *)settingsDictionary{
    _settingsDictionary = settingsDictionary;
    self.maxOffset.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET]floatValue];
    self.offset.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_OFFSET]floatValue];
    self.multiplier.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER]floatValue];
    self.pixelFilter.floatValue = [[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_SPF]floatValue];
    [self.transformData setSelectedSegment:MAX(0,MIN(2,[[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_TRANSFORM]integerValue]))];
    if([self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR])
        self.color.color = [NSColor colorFromHexString:[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR]];
    
    if([self.delegate typeOfColoring] < 4)self.color.enabled = NO;
}

-(void)selectedChannel:(id)sender{
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.maxOffset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.offset.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_OFFSET];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.multiplier.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER];
    [self.settingsDictionary setValue:[NSNumber numberWithFloat:self.pixelFilter.floatValue] forKey:JSON_DICT_CHANNEL_SETTINGS_SPF];
    [self.settingsDictionary setValue:[NSNumber numberWithInteger:self.transformData.selectedSegment] forKey:JSON_DICT_CHANNEL_SETTINGS_TRANSFORM];
    [self.settingsDictionary setValue:[self.color.color hexEncoding] forKey:JSON_DICT_CHANNEL_SETTINGS_COLOR];
    
    [self.delegate madeChannelConfChanges];
    if([sender isMemberOfClass:[NSColorWell class]])[sender becomeFirstResponder];
}

-(void)changedChannel:(NSPopUpButton *)sender{
    [self.delegate changed:self.index for:sender.indexOfSelectedItem];
}

-(void)setTag:(NSInteger)atag{
    
    [self.background setWantsLayer:YES];
    [self.background.layer
     setBackgroundColor:atag%2 == 0?[[NSColor whiteColor] CGColor]: [[NSColor colorWithWhite:0.97 alpha:1.0f] CGColor]];
    self.index = atag;
}

-(void)setLocalIndex:(NSInteger)localIndex{
    _localIndex = localIndex;
    NSColor *color = [NSColor colorInHueAtIndex:localIndex totalColors:[self.delegate numberOfChannels] withColoringType:[self.delegate typeOfColoring] minumAmountColors:3];

    if(!color){
        if([self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR])
            color = [NSColor colorFromHexString:[self.settingsDictionary valueForKey:JSON_DICT_CHANNEL_SETTINGS_COLOR]];
        else
            color = [NSColor colorInHueAtIndex:localIndex totalColors:[self.delegate numberOfChannels] withColoringType:2 minumAmountColors:3];
    }
    
    self.color.color = color;
    
    //[self.selectChannel selectItemAtIndex:localIndex];
    [self.selectChannel selectItemWithTitle:self.channels[MIN(self.index, self.channels.count - 1)]];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
