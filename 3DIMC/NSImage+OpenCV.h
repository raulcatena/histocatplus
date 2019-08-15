//
//  OpenCV.h
//  CVTest
//
//  Created by Aaron Hillegass on 6/28/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

// check() is a macro in the Apple stuff and a function
// declared in opencv/core/utilities.hpp
#undef check
#import <AppKit/AppKit.h>

using namespace cv;

@interface NSImage (OpenCV) {
    
}

//+ (NSImage *)imageWithCVMat:(const cv::Mat&)cvMat;
+ (NSImage *)imageWithRef:(CGImageRef)ref;
+ (NSImage *)imageWithCVMat:(const cv::Mat&)cvMat;
+ (CGImageRef)refWithCVMat:(const cv::Mat&)cvMat;

//Image transformations
//http://www.bogotobogo.com/OpenCV/opencv_3_tutorial_imgproc_gausian_median_blur_bilateral_filter_image_smoothing.php

- (Mat)matAveragingBlurred:(unsigned)kernelSize;
- (Mat)matGaussianBlurred:(unsigned)kernelSize;
- (Mat)matMedianBlurred:(unsigned)kernelSize;
- (Mat)matLog:(unsigned)kernelSize;
- (Mat)matCanny:(unsigned)kernelSize;
- (Mat)matGaussianGradient:(unsigned)kernelSize;
- (Mat)matGaussianGradientAngle:(unsigned)kernelSize;
- (uchar *)dataAveragingBlurred:(unsigned)kernelSize;
- (uchar *)dataGaussianBlurred:(unsigned)kernelSize;
- (uchar *)dataLog:(unsigned)kernelSize;
- (uchar *)dataCanny:(unsigned)kernelSize;
- (uchar *)dataGaussianGradient:(unsigned)kernelSize;
- (uchar *)dataGaussianGradientAngle:(unsigned)kernelSize;
- (NSImage *)averagingBlurred:(unsigned)kernelSize;
- (NSImage *)gaussianBlurred:(unsigned)kernelSize;
- (NSImage *)medianBlurred:(unsigned)kernelSize;
- (NSImage *)bilateralBlurred:(unsigned)kernelSize;
- (NSImage *)log:(unsigned)kernelSize;
- (NSImage *)canny:(unsigned)kernelSize;
- (NSImage *)gaussianGradient:(unsigned)kernelSize;
- (NSImage *)gaussianGradientAngle:(unsigned)kernelSize;

//Helpers for segmentation
-(Mat)obtainCentroidpixelsMat;
-(NSImage *)obtainCentroidpixels;
-(uchar *)obtainCentroidpixelsData;

@property(nonatomic, readonly) cv::Mat CVMat;
@property(nonatomic, readonly) cv::Mat CVGrayscaleMat;

@end
