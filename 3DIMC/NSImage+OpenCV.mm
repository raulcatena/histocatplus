//
//  OpenCV.m
//  CVTest
//
//  Created by Aaron Hillegass on 6/28/16.
//  Copyright © 2016 Big Nerd Ranch. All rights reserved.
//

#import "NSImage+OpenCV.h"
#import "NSImage+Utilities.h"

using namespace cv;

@implementation NSImage (OpenCV)



-(UInt8 *)data{
    
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL/*data - pass NULL to let CG allocate the memory*/,
                                                   [self size].width,
                                                   [self size].height,
                                                   8 /*bitsPerComponent*/,
                                                   4 * [self size].width /*bytesPerRow - CG will calculate it for you if it's allocating the data.  This might get padded out a bit for better alignment*/,
                                                   [[NSColorSpace genericRGBColorSpace] CGColorSpace],
                                                   //kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
                                                   kCGImageAlphaNoneSkipLast);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithCGContext:bitmapCtx flipped:NO]];
    
    [self drawInRect:NSMakeRect(0,0, [self size].width, [self size].height) fromRect:NSZeroRect operation:NSCompositingOperationCopy fraction:1.0];
    
    
    void * data_ = CGBitmapContextGetData(bitmapCtx);
    size_t size_data = [self size].width * [self size].height * 4;
    UInt8 * retVal = (UInt8 *)malloc(size_data);
    memcpy(retVal, data_, size_data);
    CGContextRelease(bitmapCtx);
    [NSGraphicsContext restoreGraphicsState];
    return retVal;
}


-(cv::Mat)CVMat
{
    UInt8 * data_ = [self data];
    CGFloat cols = self.size.width;
    CGFloat rows = self.size.height;
    Mat m(rows, cols, CV_8UC4, data_);
    Mat retVal = m.clone();
    free(data_);
    return retVal;
    
    
//    CGImageRef imageRef = [self CGImage];
//
//
//    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
//    CGFloat cols = self.size.width;
//    CGFloat rows = self.size.height;
//    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
//
//    CGContextRef contextRef = CGBitmapContextCreate(NULL,                 // Pointer to backing data
//                                                    cols,                      // Width of bitmap
//                                                    rows,                     // Height of bitmap
//                                                    8,                          // Bits per component
//                                                    cvMat.step[0],              // Bytes per row
//                                                    colorSpace,                 // Colorspace
//                                                    kCGImageAlphaNoneSkipLast |
//                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
//
//    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), imageRef);
//
//    void * data_context = CGBitmapContextGetData(contextRef);
//    memcpy(cvMat.data, data_context, rows * cols * 4);
//
//    CGContextRelease(contextRef); // This OK? Probably not, the context ref shares pointer with the CVMat returned
//    //    CGImageRelease(imageRef); // This is OK, Release causes a bug
//    CGColorSpaceRelease(colorSpace);
//
//    return cvMat.clone();
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
    CGContextRelease(contextRef);// This OK? Probably not, the context ref shares pointer with the CVMat returned
    CGImageRelease(imageRef);// This is OK, as data is copied
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

+ (NSImage *)imageWithRef:(CGImageRef)ref{
    return [[NSImage alloc]initWithCGImage:ref size:NSMakeSize(CGImageGetWidth(ref), CGImageGetHeight(ref))];
}

+ (NSImage *)imageWithCVMat:(const cv::Mat &)cvMat
{
    CGImageRef ref = [NSImage refWithCVMat:cvMat];
    if(ref){
        NSImage * im = [NSImage imageWithRef:ref];
        CGImageRelease(ref);
        return im;
    }else{
        return nil;
    }
}

+ (CGImageRef)refWithCVMat:(const cv::Mat&)cvMat
{

//    This was a bug. It is important to copy the data since the CvMat, when out of scope releases the memory and garbage enters the buffer.
//    NSData *data = [NSData dataWithBytesNoCopy:cvMat.data
//                                        length:cvMat.elemSize() * cvMat.total()
//                                  freeWhenDone:NO];

//    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    CGImageAlphaInfo alphaInfo;
    const unsigned width = cvMat.cols;
    const unsigned height = cvMat.rows;
    
    if (cvMat.elemSize() == 1)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
        alphaInfo = kCGImageAlphaNone;
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        alphaInfo = kCGImageAlphaNoneSkipLast;
    }
    
    UInt8 * data = (UInt8 *)calloc(cvMat.total() * 4, sizeof(UInt8));
    
    CGImageRef imageRef = NULL;
    
    if(data){
        memcpy(data, cvMat.data, cvMat.total() * cvMat.elemSize() * sizeof(UInt8));
        
        CGImageAlphaInfo info;
        if (cvMat.elemSize() == 1)
            info = kCGImageAlphaNone;
        else
            info = kCGImageAlphaNoneSkipLast;
        
        CGContextRef ctx = CGBitmapContextCreate(data,
                                                 width,
                                                 height,
                                                 8,
                                                 cvMat.elemSize() * width,
                                                 colorSpace,
                                                 info);
        
        imageRef = CGBitmapContextCreateImage(ctx);
        
        
        //    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        //
        //    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
        //                                        cvMat.rows,                                     // Height
        //                                        8,                                              // Bits per component
        //                                        8 * cvMat.elemSize(),                           // Bits per pixel
        //                                        cvMat.step[0],                                  // Bytes per row
        //                                        colorSpace,                                     // Colorspace
        //                                        alphaInfo,                                      // Use to be None    // Bitmap info flags
        //                                        provider,                                       // CGDataProviderRef
        //                                        NULL,                                           // Decode
        //                                        false,                                          // Should interpolate
        //                                        kCGRenderingIntentDefault);                     // Intent
        
        //    CGDataProviderRelease(provider);
        
        
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorSpace);
        if(data)
            free(data);
    }
    
    return imageRef;
}


//- (instancetype)initWithCVMat:(const cv::Mat&)cvMat
//{
//
//    self = [self init];
//    if(self){
//        CGImageRef imageRef = [NSImage refWithCVMat:cvMat];
//        NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
//        //        NSImage *image = [[NSImage alloc] init];
//        [self addRepresentation:bitmapRep];
//        //CGImageRelease(imageRef);// This was not good. It seems that the NSImage uses the same memory as the CGImageRef
//    }
//    return self;
//}

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
    return mat.data;
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
    return mat.data;
}
- (NSImage *)gaussianBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    return [NSImage imageWithCVMat:[self matGaussianBlurred:kernelSize]];
}

#pragma mark Median Blurred
- (Mat)matMedianBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    Mat matRep = [self CVMat];
    Mat dst;
    medianBlur(matRep, dst, kernelSize);
    return dst;
}
- (uchar *)dataMedianBlurred:(unsigned)kernelSize{
    Mat mat = [self matMedianBlurred:kernelSize];
    return mat.data;
}
- (NSImage *)medianBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    return [NSImage imageWithCVMat:[self matMedianBlurred:kernelSize]];
}

#pragma mark Median Blurred
- (Mat)matBilateralBlurred:(unsigned)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    Mat matRep = [self CVMat];
    Mat dst;
    bilateralFilter(matRep, dst, kernelSize, kernelSize * 4, kernelSize * 4);
    return dst;
}
- (uchar *)dataBilateralBlurred:(unsigned)kernelSize{
    Mat mat = [self matBilateralBlurred:kernelSize];
    return mat.data;
}
- (NSImage *)bilateralBlurred:(unsigned int)kernelSize{
    if(kernelSize % 2 == 0)kernelSize++;
    return [NSImage imageWithCVMat:[self matBilateralBlurred:kernelSize]];
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
    return mat.data;
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

-(Mat)obtainCentroidpixelsMat{
    Mat matRep = [self matGaussianBlurred:3];
    cv::Mat gray;
    cv::cvtColor(matRep, gray, cv::COLOR_BGR2GRAY);
    
//    std::vector<cv::Vec3f> circles;
//    cv::HoughCircles(gray, circles, cv::HOUGH_GRADIENT, 2, 7, 150, 2, 2, 8);
//    std::cout << circles.size() << std::endl;
    
    Mat img_or, img_or_ad, img_bw, img_bw_2;
    adaptiveThreshold(gray, img_or_ad, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY, 15, 1);
    threshold(gray, img_or, 10, 255, THRESH_BINARY);
    
    img_or = img_or_ad & img_or;
    
    //erode(img_or, img_bw_2, Mat());//Smaller kernels
    dilate(img_or, img_bw, Mat());
    erode(img_bw, img_bw, Mat());
    erode(img_bw, img_bw, Mat());
    erode(img_bw, img_bw, Mat());
    img_or /= 2;
    
    Mat sum = img_or + img_bw;
    Mat lt;
    compare(gray, sum, lt, CMP_LT);
    sum +=  gray.mul(lt/255);
    GaussianBlur(sum, sum, cv::Size(9, 9), 1, 1, BORDER_CONSTANT);
    return sum;
    
//    for( size_t i = 0; i < circles.size(); i++ )
//    {
//        cv::Vec3i c = circles[i];
//        cv::Point center = cv::Point(c[0], c[1]);
//        cv::line(gray, center, center, cv::Scalar(255,255,255));
//        cv::circle( gray, center, 1, cv::Scalar(255,255,255), 1, cv::LINE_AA);
//    }
//    return gray;
}

-(NSImage *)obtainCentroidpixels{
    Mat matRep = [self obtainCentroidpixelsMat];
    return [NSImage imageWithCVMat:matRep];
}

-(uchar *)obtainCentroidpixelsData{
    Mat matRep = [self obtainCentroidpixelsMat];
    return matRep.data;
}

@end
