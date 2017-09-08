//
//  OpenCV.m
//  CVTest
//
//  Created by Aaron Hillegass on 6/28/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

#import "NSImage+OpenCV.h"

using namespace cv;

@implementation NSImage (OpenCV)

-(CGImageRef)CGImage
{
    
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL/*data - pass NULL to let CG allocate the memory*/,
                                                   [self size].width,
                                                   [self size].height,
                                                   8 /*bitsPerComponent*/,
                                                   0 /*bytesPerRow - CG will calculate it for you if it's allocating the data.  This might get padded out a bit for better alignment*/,
                                                   [[NSColorSpace genericRGBColorSpace] CGColorSpace],
                                                   //kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
                                                   kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapCtx flipped:NO]];
    [self drawInRect:NSMakeRect(0,0, [self size].width, [self size].height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapCtx);
    CGContextRelease(bitmapCtx);
    [NSGraphicsContext restoreGraphicsState];
    return cgImage;
}

+ (NSImage *)imageWithRef:(CGImageRef)ref{
    NSImage *im = [[NSImage alloc]initWithCGImage:ref size:NSMakeSize(CGImageGetWidth(ref), CGImageGetHeight(ref))];
    CFRelease(ref);
    return im;
}


-(cv::Mat)CVMat
{
    CGImageRef imageRef = [self CGImage];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
    CGContextRelease(contextRef);
    CGImageRelease(imageRef);

    return cvMat;
}

-(cv::Mat)CVGrayscaleMat
{
    CGImageRef imageRef = [self CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    cv::Mat cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                     // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNone |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    return cvMat;
}

+ (NSImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    return [[NSImage alloc] initWithCVMat:cvMat];
}


- (instancetype)initWithCVMat:(const cv::Mat&)cvMat
{
    
//    CGImageRef imageRef = [self refWithCVMat:cvMat];
//    
//    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
//    NSImage *image = [[NSImage alloc] init];
//    [image addRepresentation:bitmapRep];
//    
//    CGImageRelease(imageRef);
//    
//    return image;
    self = [self init];
    if(self){
        CGImageRef imageRef = [self refWithCVMat:cvMat];
        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
        //        NSImage *image = [[NSImage alloc] init];
        [self addRepresentation:bitmapRep];
        CGImageRelease(imageRef);
    }
    return self;
}

- (CGImageRef)refWithCVMat:(const cv::Mat&)cvMat
{
//    This was a bug. It is important to copy the data since the CvMat, when out of scope releases the memory and garbage enters the buffer.
//    NSData *data = [NSData dataWithBytesNoCopy:cvMat.data
//                                        length:cvMat.elemSize() * cvMat.total()
//                                  freeWhenDone:NO];

    NSData *data = [NSData dataWithBytes:cvMat.data
                                        length:cvMat.elemSize() * cvMat.total()
                                  ];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    
    return imageRef;
}

#pragma mark Average Blurred
- (Mat)matAveragingBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    Mat matRep = [self CVMat];
    Mat dst;
    blur(matRep, dst, cv::Size(kernelSize,kernelSize));
    return dst;
}
- (uchar *)dataAveragingBlurred:(unsigned)kernelSize{
    Mat mat = [self matAveragingBlurred:kernelSize];
    return mat.data;;
}
- (NSImage *)averagingBlurred:(unsigned)kernelSize{
    return [NSImage imageWithCVMat:[self matAveragingBlurred:kernelSize]];
}

#pragma mark Gaussian Blurred
- (Mat)matGaussianBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    Mat matRep = [self CVMat];
    Mat dst;
    GaussianBlur(matRep, dst, cv::Size(kernelSize,kernelSize), 0, 0);
    return dst;
}
- (uchar *)dataGaussianBlurred:(unsigned)kernelSize{
    Mat mat = [self matGaussianBlurred:kernelSize];
    return mat.data;;
}
- (NSImage *)gaussianBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    return [NSImage imageWithCVMat:[self matGaussianBlurred:kernelSize]];
}

#pragma mark Laplacian of Gaussian Blurred
- (Mat)matLog:(unsigned)kernelSize{
    Mat src, dst;
    
    src = [self CVMat];
    
    /// Remove noise by blurring with a Gaussian filter
    GaussianBlur( src, src, cv::Size(kernelSize,kernelSize), 0, 0, BORDER_DEFAULT );
    //cvtColor( src, gray, CV_RGB2GRAY );
    
    /// Apply Laplace function
    Laplacian( src, dst, CV_8UC4, 3, 1, 0, BORDER_DEFAULT );
    //convertScaleAbs( dst, abs_dst );
    return dst;
}
- (uchar *)dataLog:(unsigned)kernelSize{
    Mat mat = [self matLog:kernelSize];
    return mat.data;;
}
- (NSImage *)log:(unsigned)kernelSize{
    return [NSImage imageWithCVMat:[self matLog:kernelSize]];
}

#pragma mark Canny Edge
- (Mat)matCanny:(unsigned)kernelSize{
    Mat src, dst;
    
    src = [self CVMat];
    
    /// Remove noise by blurring with a Gaussian filter
    GaussianBlur( src, src, cv::Size(kernelSize,kernelSize), 0, 0, BORDER_DEFAULT );
    //cvtColor( src, gray, CV_RGB2GRAY );
    
    /// Apply Canny function
    Canny(src, dst, 30, 200);
    //convertScaleAbs( dst, abs_dst );
    return dst;
}
- (uchar *)dataCanny:(unsigned)kernelSize{
    Mat mat = [self matCanny:kernelSize];
    return mat.data;;
}
- (NSImage *)canny:(unsigned)kernelSize{
    return [NSImage imageWithCVMat:[self matCanny:kernelSize]];
}

//http://stackoverflow.com/questions/19815732/what-is-gradient-orientation-and-gradient-magnitude
#pragma mark Gaussian first derivate
- (Mat)matGaussianGradient:(unsigned)kernelSize{
    Mat src;
    
    src = [self CVMat];
    
    Mat Sx;
    Sobel(src, Sx, CV_32F, 1, 0, kernelSize);
    
    Mat Sy;
    Sobel(src, Sy, CV_32F, 0, 1, kernelSize);
    
    Mat mag;
    magnitude(Sx, Sy, mag);
    return mat2gray(mag);
}
Mat mat2gray(const cv::Mat& src)
{
    Mat dst;
    normalize(src, dst, 0.0, 255.0, cv::NORM_MINMAX, CV_8U);
    
    return dst;
}
Mat orientationMap(const cv::Mat& mag, const cv::Mat& ori, double thresh = 1.0)
{
    Mat oriMap = Mat::zeros(ori.size(), CV_8UC3);
    Vec3b red(0, 0, 255);
    Vec3b cyan(255, 255, 0);
    Vec3b green(0, 255, 0);
    Vec3b yellow(0, 255, 255);
    for(int i = 0; i < mag.rows*mag.cols; i++)
    {
        float* magPixel = reinterpret_cast<float*>(mag.data + i*sizeof(float));
        if(*magPixel > thresh)
        {
            float* oriPixel = reinterpret_cast<float*>(ori.data + i*sizeof(float));
            Vec3b* mapPixel = reinterpret_cast<Vec3b*>(oriMap.data + i*3*sizeof(char));
            if(*oriPixel < 90.0)
                *mapPixel = red;
            else if(*oriPixel >= 90.0 && *oriPixel < 180.0)
                *mapPixel = cyan;
            else if(*oriPixel >= 180.0 && *oriPixel < 270.0)
                *mapPixel = green;
            else if(*oriPixel >= 270.0 && *oriPixel < 360.0)
                *mapPixel = yellow;
        }
    }
    
    return oriMap;
}
- (uchar *)dataGaussianGradient:(unsigned)kernelSize{
    Mat mat = [self matGaussianGradient:kernelSize];
    return mat.data;;
}
- (NSImage *)gaussianGradient:(unsigned)kernelSize{
    return [NSImage imageWithCVMat:[self matGaussianGradient:kernelSize]];
}
#pragma mark Gaussian first derivate angle
- (Mat)matGaussianGradientAngle:(unsigned)kernelSize{
    Mat src;
    
    src = [self CVMat];
    
    Mat Sx;
    Sobel(src, Sx, CV_32F, 1, 0, kernelSize);
    
    Mat Sy;
    Sobel(src, Sy, CV_32F, 0, 1, kernelSize);
    
    Mat mag, ori;
    magnitude(Sx, Sy, mag);
    phase(Sx, Sy, ori, true);
    //Mat oriMap = orientationMap(mag, ori, 1.0);
    return mat2gray(ori);
}
- (uchar *)dataGaussianGradientAngle:(unsigned)kernelSize{
    Mat mat = [self matGaussianGradientAngle:kernelSize];
    return mat.data;;
}
- (NSImage *)gaussianGradientAngle:(unsigned)kernelSize{
    return [NSImage imageWithCVMat:[self matGaussianGradientAngle:kernelSize]];
}


//JIC

//- (instancetype)initWithCVMat:(const cv::Mat&)cvMat
//{
//    NSData *data = [NSData dataWithBytesNoCopy:cvMat.data
//                                        length:cvMat.elemSize() * cvMat.total()
//                                  freeWhenDone:NO];
//    
//    CGColorSpaceRef colorSpace;
//    
//    if (cvMat.elemSize() == 1)
//    {
//        colorSpace = CGColorSpaceCreateDeviceGray();
//    }
//    else
//    {
//        colorSpace = CGColorSpaceCreateDeviceRGB();
//    }
//    
//    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
//    
//    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
//                                        cvMat.rows,                                     // Height
//                                        8,                                              // Bits per component
//                                        8 * cvMat.elemSize(),                           // Bits per pixel
//                                        cvMat.step[0],                                  // Bytes per row
//                                        colorSpace,                                     // Colorspace
//                                        kCGImageAlphaNone,  // Bitmap info flags
//                                        provider,                                       // CGDataProviderRef
//                                        NULL,                                           // Decode
//                                        false,                                          // Should interpolate
//                                        kCGRenderingIntentDefault);                     // Intent
//    
//    
//    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
//    NSImage *image = [[NSImage alloc] init];
//    [image addRepresentation:bitmapRep];
//    
//    CGImageRelease(imageRef);
//    CGDataProviderRelease(provider);
//    CGColorSpaceRelease(colorSpace);
//    
//    return image;
//}

@end
