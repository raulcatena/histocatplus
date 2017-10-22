//
//  AppDelegate.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "AppDelegate.h"
#import "IMCPreferencesController.h"

//RCF In Sierra http://stackoverflow.com/questions/39449665/xcode-8-cant-archive-command-usr-bin-codesign-failed-with-exit-code-1

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    if(!VIEWER_ONLY && !VIEWER_HISTO)
        [[[NSApplication sharedApplication] mainMenu]removeItemAtIndex:6];
    else
        [[[NSApplication sharedApplication] mainMenu]removeItemAtIndex:5];
    
    [[NSColorPanel sharedColorPanel]setShowsAlpha:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void)preferences:(id)sender{
    if(!self.preferences) self.preferences = [[IMCPreferencesController alloc]init];
    [[self.preferences window] makeKeyAndOrderFront:self.preferences];
}

@end
