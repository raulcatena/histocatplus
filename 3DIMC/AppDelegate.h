//
//  AppDelegate.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class IMCPreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) IMCPreferencesController *preferences;

- (IBAction)preferences:(id)sender;

@end

