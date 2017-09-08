//
//  IMCBrushTools.h
//  3DIMC
//
//  Created by Raul Catena on 2/14/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IMCBrushBullet.h"

typedef enum {
    IMC_BRUSH_BRUSH,
    IMC_BRUSH_ERASE,
    IMC_BRUSH_BUCKET,
    IMC_BRUSH_BUCKET_ERASE
} BrushType;

@interface IMCBrushTools : NSView
@property (nonatomic, weak) IBOutlet NSSegmentedControl *typeOfBrush;
@property (nonatomic, weak) IBOutlet NSStepper *brushSize;
@property (nonatomic, weak) IBOutlet IMCBrushBullet *brushBullet;

@property (nonatomic, weak) IBOutlet NSSlider *tolerance;
@property (nonatomic, weak) IBOutlet NSTextField *toleranceText;
@property (nonatomic, weak) IBOutlet NSTextField *brushSizeText;

-(IBAction)changedValue:(id)sender;
-(BrushType)brushType;

-(void)paintOrRemove:(BOOL)remove mask:(UInt8 *)paintMask index:(NSInteger)index fillInteger:(NSInteger)fill imageWidth:(NSInteger)width imageHeight:(NSInteger)heigth;
-(void)paintOrRemove:(BOOL)remove mask32Bit:(int *)paintMask index:(NSInteger)index fillInteger:(int)fill imageWidth:(NSInteger)width imageHeight:(NSInteger)heigth;
-(void)fillBufferMask:(UInt8 *)paintMask fromDataBuffer:(UInt8 *)buffer index:(NSInteger)index width:(NSInteger)width height:(NSInteger)height fill:(NSInteger)fill;

@end
