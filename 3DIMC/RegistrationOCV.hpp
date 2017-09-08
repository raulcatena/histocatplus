//
//  RegistrationOCV.hpp
//  3DIMC
//
//  Created by Raul Catena on 2/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#ifndef RegistrationOCV_hpp
#define RegistrationOCV_hpp

#include <stdio.h>

#endif /* RegistrationOCV_hpp */
using namespace cv;
using namespace std;

void registerImages(Mat image1, Mat image2);
void testMatImages(Mat image1, Mat image2);
void init_warp(CvMat* W, float wz, float tx, float ty);

void surfPlusHomography(Mat img1, Mat img2);
