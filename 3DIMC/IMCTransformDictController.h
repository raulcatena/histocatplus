//
//  IMCTransformDictController.h
//  3DIMC
//
//  Created by Raul Catena on 1/30/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol TransformDelegate <NSObject>

-(void)refresh;

@end

@interface IMCTransformDictController : NSView

@property (nonatomic, weak) id<TransformDelegate>delegate;

@property (nonatomic, strong) NSMutableDictionary *transformDict;
@property (nonatomic, weak) IBOutlet NSStepper *angle;
@property (nonatomic, weak) IBOutlet NSStepper *compresionX;
@property (nonatomic, weak) IBOutlet NSStepper *compresionY;
@property (nonatomic, weak) IBOutlet NSStepper *offsetX;
@property (nonatomic, weak) IBOutlet NSStepper *offsetY;
@property (nonatomic, weak) IBOutlet NSTextField *angleField;
@property (nonatomic, weak) IBOutlet NSTextField *compresionXField;
@property (nonatomic, weak) IBOutlet NSTextField *compresionYField;
@property (nonatomic, weak) IBOutlet NSTextField *offsetXField;
@property (nonatomic, weak) IBOutlet NSTextField *offsetYField;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *coarseValue;

-(IBAction)refresh:(id)sender;
-(IBAction)changedCoarse:(NSSegmentedControl *)sender;
-(void)updateFromDict;

@end
