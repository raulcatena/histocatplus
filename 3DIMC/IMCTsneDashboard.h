//
//  IMCTsneDashboard.h
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCTsneDashboard : NSView
@property (nonatomic, weak) IBOutlet NSSlider *perplexity;
@property (nonatomic, weak) IBOutlet NSTextField *perplexityField;
-(IBAction)changed:(id)sender;
@end
