//
//  IMCPreferencesController.h
//  IMCReader
//
//  Created by Raul Catena on 11/23/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCPreferencesController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *cpLocationTV;
@property (nonatomic, weak) IBOutlet NSTextField *ijLocationTV;
@property (nonatomic, weak) IBOutlet NSTextField *ilkLocationTV;
@property (nonatomic, weak) IBOutlet NSTextField *rLocationTV;
@property (nonatomic, weak) IBOutlet NSButton *useMetal;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *colorSpaceFav;

-(IBAction)selectCPLocation:(id)sender;
-(IBAction)selectIJLocation:(id)sender;
-(IBAction)selectIltkLocation:(id)sender;
-(IBAction)selectRLocation:(id)sender;
-(IBAction)changedColorSpaceFav:(id)sender;
-(IBAction)toogleMetal:(id)sender;

@end
