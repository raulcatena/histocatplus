//
//  OpenGLViewNew.h
//  IMCReader
//
//  Created by Raul Catena on 11/21/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl3.h>
#import <GLKit/GLKit.h>


typedef enum
{
    COLORING_TYPE_DIFFUSE_LIGHT_0,
    COLORING_TYPE_DIFFUSE_EMISSIVE
} ColoringType;

typedef enum
{
    ALPHA_MODE_OPAQUE,
    ALPHA_MODE_FIXED,
    ALPHA_MODE_ADAPTIVE
} AlphaMode;

@protocol Get3DData <NSObject>
@optional
-(float ***)threeDData;
-(bool *)showMask;
-(NSArray *)colors;//Array of Arrays with colors
-(NSColor *)backgroundColor;
-(CGRect)rectToRender;
-(NSUInteger)witdhModel;
-(NSUInteger)heightModel;
-(NSUInteger)numberOfStacks;
-(NSIndexSet *)stacksIndexSet;
-(NSUInteger)numberOfChannels;
-(NSArray *)inOrderIndexes;
-(NSArray *)zOffSets;
-(float)combinedAlpha;
-(ColoringType)coloringType;//0 Diffuse light 1 Emissive color
-(float *)zValues;
-(float *)thicknesses;
-(float)totalThickness;
-(NSPoint)centerInterestArea;
-(AlphaMode)alphaMode;
-(NSArray *)channelsForCell;
-(NSButton *)legends;
@end


@interface OpenGLView : NSOpenGLView
{
    NSTimer *pTimer;
    @public
    CGFloat zoom;
    NSPoint position;
    CGPoint rotation;
}

@property (nonatomic, weak) id<Get3DData>delegate;
@property (nonatomic, assign) float defaultThickness;

@property (nonatomic, assign) float leftXOffset;
@property (nonatomic, assign) float rightXOffset;
@property (nonatomic, assign) float lowerYOffset;
@property (nonatomic, assign) float upperYOffset;
@property (nonatomic, assign) float nearZOffset;
@property (nonatomic, assign) float farZOffset;

-(void)refresh;
-(void)applyRotationWithInternalState;
-(void)rotateX:(float)angleX Y:(float)angleY Z:(float)angleZ;

@end
