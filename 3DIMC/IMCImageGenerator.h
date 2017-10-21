//
//  IMCImageGenerator.h
//  3DIMC
//
//  Created by Raul Catena on 1/21/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;
@class IMCTiledScrollView;
@class IMCPixelClassification;
@class IMCComputationOnMask;

typedef struct RgbColor
{
    unsigned char r;
    unsigned char g;
    unsigned char b;
} RgbColor;

typedef struct HsvColor
{
    unsigned char h;
    unsigned char s;
    unsigned char v;
} HsvColor;


@interface IMCImageGenerator : NSObject


//Pixel Filter
void applyFilterToPixelData(UInt8 * pixelData, NSInteger width, NSInteger height, NSInteger mode, float factor, NSInteger layers, NSInteger channels);
void applySmoothingFilterToPixelData(UInt8 * pixelData, NSInteger width, NSInteger height, NSInteger mode, NSInteger layers);
void threeDMeanBlur(float *** data, NSInteger width, NSInteger height, NSArray * indexesArranged, NSIndexSet * channels, NSInteger mode, bool *mask, float * deltas_z);

//Main image assembly function
+(NSImage *)imageForImageStacks:(NSMutableArray<IMCImageStack*>*)setStacks indexes:(NSArray *)indexArray withColoringType:(NSInteger)coloringType customColors:(NSArray *)customColors minNumberOfColors:(NSInteger)minAmountColors width:(NSInteger)width height:(NSInteger)height withTransforms:(BOOL)applyTransforms blend:(CGBlendMode)blend andMasks:(NSArray<IMCPixelClassification *> *)masks andComputations:(NSArray<IMCComputationOnMask *>*)computations maskOption:(MaskOption)maskOption maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor isAlignmentPair:(BOOL)isAlignmentPair brightField:(BOOL)brightField;

//Helper for exporting
+(CGImageRef)rawImageFromImage:(IMCImageStack *)imageStack index:(NSInteger)imageIndex numberOfBits:(int)bits;
//Helper for registration
+(CGImageRef)whiteRotatedBufferForImage:(IMCImageStack *)stack atIndex:(NSInteger)index superCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper;

+(CGImageRef)refForMaskComputation:(IMCComputationOnMask *)computation
                           indexes:(NSArray *)indexArray
                      coloringType:(NSInteger)coloringType
                      customColors:(NSArray *)colors
                 minNumberOfColors:(NSInteger)minAmountColors
                             width:(NSInteger)width
                            height:(NSInteger)height
                    withTransforms:(BOOL)applyTransforms
                         blendMode:(CGBlendMode)blend
                        maskOption:(MaskOption)maskOption
                          maskType:(MaskType)maskType
                   maskSingleColor:(NSColor *)maskSingleColor
                       brightField:(BOOL)brightField;

+(CGImageRef)refMask:(IMCPixelClassification *)mask coloringType:(NSInteger)coloringType width:(NSInteger)width height:(NSInteger)height withTransforms:(BOOL)applyTransforms blendMode:(CGBlendMode)blend maskOption:(MaskOption)maskOption maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor;

+(NSImage *)imageWithArrayOfCGImages:(NSArray *)array width:(NSInteger)width height:(NSInteger)height blendMode:(CGBlendMode)blend;
//Other functions
+(CGImageRef)imageFromCArrayOfValues:(UInt8 *)array color:(NSColor *)color width:(NSInteger)width height:(NSInteger)height startingHueScale:(int)startHue hueAmplitude:(int)amplitude direction:(BOOL)positive ecuatorial:(BOOL)ecHueTraverse brightField:(BOOL)brightField;

+(CGImageRef)whiteImageFromCArrayOfValues:(UInt8 *)array width:(NSInteger)width height:(NSInteger)height;

+(UInt8 *)bufferForImageRef:(CGImageRef)ref;

//Color Masks
+(UInt8 *)mapMaskTo255:(UInt8 *)mask length:(NSInteger)length toMax:(float)max;//Utility to turn training masks in colorable with HUE
+(CGImageRef)colorMask:(int *)mask numberOfColors:(NSInteger)colors singleColor:(NSColor *)color width:(NSInteger)width height:(NSInteger)height;

RgbColor HsvToRgb(HsvColor hsv);
RgbColor RgbFromFloatUnit(float unit);


@end
