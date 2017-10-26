//
//  IMCKMeansDashboard.h
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCKMeansDashboard : NSView
@property (nonatomic, weak) IBOutlet NSSlider *clusters;
@property (nonatomic, weak) IBOutlet NSTextField *clustersField;
@property (nonatomic, weak) IBOutlet NSSlider *restarts;
@property (nonatomic, weak) IBOutlet NSTextField *restartsField;
-(IBAction)changed:(id)sender;
@end
