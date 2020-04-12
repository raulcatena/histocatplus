//
//  IMCFileExporter.h
//  3DIMC
//
//  Created by Raul Catena on 1/28/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;
@class IMCScrollView;
@class IMCComputationOnMask;
@class IMCLoader;
@class IMCPixelClassification;

@interface IMCFileExporter : NSObject

//Quick saving
+(void)saveTIFFFromImageStack:(IMCImageStack *)stack atIndex:(int)index atPath:(NSString *)path bits:(int)bits;//Quick save as TIFF
+(NSString *)saveTIFFsFolder:(IMCImageStack *)stack atFolderPath:(NSString *)dirpath;//Save channels filewise for miCAT

//Multipage saving
//Save all channels utility function. May deprecate for the generic one below
+(void)saveMultipageTiffAllChannels:(IMCImageStack *)stack  path:(NSString *)path;
+(void)saveMultipageTiffFromStack:(IMCImageStack *)stack forSelectedIndexes:(NSIndexSet *)indexes atDirPath:(NSString *)dirpath  fileName:(NSString *)fileName;//Save multipage if filename null
//this is a subroutine, but useful to expose
+(void)writeArrayOfRefImages:(NSArray *)images withTitles:(NSArray *)titles atPath:(NSString *)path in16bits:(BOOL)sixteenBits;//Array of ImageRefs multipage

//Mask saving
+(void)saveMask:(IMCComputationOnMask *)mask channel:(NSInteger)channel path:(NSString *)path;

//JPEG quick saving
+(void)saveJPEGFromScroll:(IMCScrollView *)scroll withPath:(NSString *)fullPath allOrZoomed:(BOOL)zoomed;
+(void)copyToClipBoardFromScroll:(IMCScrollView *)scroll allOrZoomed:(BOOL)zoomed;
+(void)copyToClipBoardFromView:(NSView *)view;
+(NSImage *)getNSImageForIMCScrollView:(IMCScrollView *)scroll zoomed:(BOOL)zoomed;
+(void)saveNSImageAsJpeg:(NSImage *)image withPath:(NSString *)path;

//Export cell data
+(BOOL)saveCSVWithComputations:(NSArray<IMCComputationOnMask *>*)computations atPath:(NSString *)path columnIndexes:(NSIndexSet *)indexSet dataCoordinator:(IMCLoader *)loader metadataIndexes:(NSIndexSet *)indexSetMetadata;
+(BOOL)saveBinaryWithComputations:(NSArray<IMCComputationOnMask *>*)computations atPath:(NSString *)path columnIndexes:(NSIndexSet *)indexSet dataCoordinator:(IMCLoader *)loader metadataIndexes:(NSIndexSet *)indexSetMetadata;
+(BOOL)saveTSVWithMetadata:(NSArray<IMCImageStack *>*)stacks atPath:(NSString *)path withCoordinator:(IMCLoader *)loader;

+(NSImage *) mergeImage:(NSImage*)a andB:(NSImage*)b fraction:(float)fraction;
@end
