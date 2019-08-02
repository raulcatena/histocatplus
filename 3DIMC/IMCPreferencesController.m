//
//  IMCPreferencesController.m
//  IMCReader
//
//  Created by Raul Catena on 11/23/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCPreferencesController.h"

@interface IMCPreferencesController ()

@end

@implementation IMCPreferencesController

-(id)init{
    return [self initWithWindowNibName:@"IMCPreferencesController"];
}

-(void)setFromUserDefaults{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    self.cpLocationTV.stringValue = [defaults valueForKey:PREF_LOCATION_DRIVE_CP]?[defaults valueForKey:PREF_LOCATION_DRIVE_CP]:@"";
    self.ijLocationTV.stringValue = [defaults valueForKey:PREF_LOCATION_DRIVE_IJ]?[defaults valueForKey:PREF_LOCATION_DRIVE_IJ]:@"";
    self.ilkLocationTV.stringValue = [defaults valueForKey:PREF_LOCATION_DRIVE_ILTK]?[defaults valueForKey:PREF_LOCATION_DRIVE_ILTK]:@"";
    self.rLocationTV.stringValue = [defaults valueForKey:PREF_LOCATION_DRIVE_R]?[defaults valueForKey:PREF_LOCATION_DRIVE_R]:@"/Library/Frameworks/R.framework";

    self.colorSpaceFav.selectedSegment = [[defaults valueForKey:PREF_COLORSPACE]integerValue];
    self.useMetal.state = [[defaults valueForKey:PREF_USE_METAL]boolValue];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setFromUserDefaults];
    
}

-(void)selectProgramLocation:(NSString *)prefHandle{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    panel.allowsMultipleSelection = NO;
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSArray* urls = [panel URLs];
            for (NSURL *url in urls) {
                NSLog(@"URL %@", url.path );
                [[NSUserDefaults standardUserDefaults]setValue:url.path forKey:prefHandle];
                [[NSUserDefaults standardUserDefaults]synchronize];
                [self setFromUserDefaults];
            }
        }
    }];
}

-(void)selectCPLocation:(id)sender{
    [self selectProgramLocation:PREF_LOCATION_DRIVE_CP];
}

-(void)selectIJLocation:(id)sender{
    [self selectProgramLocation:PREF_LOCATION_DRIVE_IJ];
}

-(void)selectIltkLocation:(id)sender{
    [self selectProgramLocation:PREF_LOCATION_DRIVE_ILTK];
}
-(void)selectRLocation:(id)sender{
    [self selectProgramLocation:PREF_LOCATION_DRIVE_R];
}

-(void)changedColorSpaceFav:(NSSegmentedControl *)sender{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:sender.selectedSegment] forKey:PREF_COLORSPACE];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

-(void)toogleMetal:(NSButton *)sender{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSNumber numberWithInteger:sender.state] forKey:PREF_USE_METAL];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

@end
