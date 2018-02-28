//
//  IMCRegistrationOCV.m
//  3DIMC
//
//  Created by Raul Catena on 2/2/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCRegistrationOCV.h"
#import "NSImage+OpenCV.h"
#include "RegistrationOCV.hpp"

using namespace cv;

@implementation IMCRegistrationOCV

+(void)alignTwoImages:(NSImage *)imageA imageB:(NSImage *)imageB{
    Mat im1 = [imageA CVMat];
    Mat im2 = [imageB CVMat];
    
    registerImages(im1, im2);
    //testMatImages(im1, im2);
    //surfPlusHomography(im1, im2);
}

@end
