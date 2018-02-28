//
//  RegistrationOCV.cpp
//  3DIMC
//
//  Created by Raul Catena on 2/3/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#include "RegistrationOCV.hpp"
#include "opencv2/core/core.hpp"
#include "opencv2/features2d/features2d.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/calib3d/calib3d.hpp"
#include "opencv2/features2d.hpp"
#include "opencv2/xfeatures2d.hpp"

using namespace xfeatures2d;

void testMatImages(Mat image1, Mat image2){
    // Convert images to gray scale;
    Mat im1_gray, im2_gray;
    cvtColor(image1, im1_gray, CV_BGR2GRAY);
    cvtColor(image2, im2_gray, CV_BGR2GRAY);
    
    // Define the motion model
    const int warp_mode = cv::MOTION_EUCLIDEAN;
    
    // Set a 2x3 or 3x3 warp matrix depending on the motion model.
    Mat warp_matrix;
    
    // Initialize the matrix to identity
    if ( warp_mode == MOTION_HOMOGRAPHY )
        warp_matrix = Mat::eye(3, 3, CV_32F);
    else
        warp_matrix = Mat::eye(2, 3, CV_32F);
    
    // Storage for warped image.
    Mat im2_aligned;
    
    if (warp_mode != cv::MOTION_HOMOGRAPHY)
        // Use warpAffine for Translation, Euclidean and Affine
        cv::warpAffine(image2, im2_aligned, warp_matrix, image1.size(), cv::INTER_LINEAR + cv::WARP_INVERSE_MAP);
    else
        // Use warpPerspective for Homography
        warpPerspective (image2, im2_aligned, warp_matrix, image1.size(),cv::INTER_LINEAR + cv::WARP_INVERSE_MAP);
    
    
    printf("%.5f \n", warp_matrix.at<double>(0,0));
    printf("%.5f \n", warp_matrix.at<double>(0,1));
    printf("%.5f \n", warp_matrix.at<double>(0,2));
    printf("%.5f \n", warp_matrix.at<double>(1,0));
    printf("%.5f \n", warp_matrix.at<double>(1,1));
    printf("%.5f \n", warp_matrix.at<double>(1,2));
    printf("\n\n----");
    printf("%.5f \n", warp_matrix.at<double>(0,0));
    printf("%.5f \n", warp_matrix.at<double>(0,1));
    printf("%.5f \n", warp_matrix.at<double>(1,0));
    printf("%.5f \n", warp_matrix.at<double>(1,1));
    printf("%.5f \n", warp_matrix.at<double>(2,0));
    printf("%.5f \n", warp_matrix.at<double>(2,1));
    
    
    
    // Show final result
    imshow("Image 1", image1);
    imshow("Image 2", image2);
    imshow("Image 2 Aligned", im2_aligned);
    waitKey(0);
    destroyWindow("Image 1");
    waitKey(0);
    destroyWindow("Image 2");
    waitKey(0);
    destroyWindow("Image 2 Aligned");
}

void init_warp(CvMat W, float wz, float tx, float ty)
{
    CV_MAT_ELEM(W, float, 0, 0) = 1;
    CV_MAT_ELEM(W, float, 1, 0) = wz;
    //CV_MAT_ELEM(W, float, 2, 0) = 0;
    
    CV_MAT_ELEM(W, float, 0, 1) = -wz;
    CV_MAT_ELEM(W, float, 1, 1) = 1;
    //CV_MAT_ELEM(W, float, 2, 1) = 0;
    
    CV_MAT_ELEM(W, float, 0, 2) = tx;
    CV_MAT_ELEM(W, float, 1, 2) = ty;
    //CV_MAT_ELEM(W, float, 2, 2) = 1;
}

Mat GetGradient(Mat src_gray)
{
    Mat grad_x, grad_y;
    Mat abs_grad_x, abs_grad_y;
    
    int scale = 1;
    int delta = 0;
    int ddepth = CV_32FC1; ;
    
    // Calculate the x and y gradients using Sobel operator
    Sobel( src_gray, grad_x, ddepth, 1, 0, 3, scale, delta, BORDER_DEFAULT );
    convertScaleAbs( grad_x, abs_grad_x );
    
    Sobel( src_gray, grad_y, ddepth, 0, 1, 3, scale, delta, BORDER_DEFAULT );
    convertScaleAbs( grad_y, abs_grad_y );
    
    // Combine the two gradients
    Mat grad;
    addWeighted( abs_grad_x, 0.5, abs_grad_y, 0.5, 0, grad );
    
    return grad;
    
}

void registerImages(Mat image1, Mat image2){
    // Convert images to gray scale;
    Mat im1_gray, im2_gray;
    cvtColor(image1, im1_gray, CV_BGR2GRAY);
    cvtColor(image2, im2_gray, CV_BGR2GRAY);
    
    // Define the motion model
    const int warp_mode = cv::MOTION_EUCLIDEAN;
    
    // Set a 2x3 or 3x3 warp matrix depending on the motion model.
    Mat warp_matrix;
    
    // Initialize the matrix to identity
    if ( warp_mode == MOTION_HOMOGRAPHY )
        warp_matrix = Mat::eye(3, 3, CV_32F);
    else
        warp_matrix = Mat::eye(2, 3, CV_32F);
    
    // Specify the number of iterations.
    int number_of_iterations = 5000;
    
    // Specify the threshold of the increment
    // in the correlation coefficient between two iterations
    double termination_eps = 1e-10;
    
    // Define termination criteria
    TermCriteria criteria (TermCriteria::COUNT+TermCriteria::EPS, number_of_iterations, termination_eps);
    
    
    // Run the ECC algorithm. The results are stored in warp_matrix.
    findTransformECC(
                     GetGradient(im1_gray),
                     GetGradient(im2_gray),
                     warp_matrix,
                     warp_mode,
                     criteria
                     );
    
    // Storage for warped image.
    Mat im2_aligned;
    
    if (warp_mode != cv::MOTION_HOMOGRAPHY)
        // Use warpAffine for Translation, Euclidean and Affine
        cv::warpAffine(image2, im2_aligned, warp_matrix, image1.size(), cv::INTER_LINEAR + cv::WARP_INVERSE_MAP);
    else
        // Use warpPerspective for Homography
        warpPerspective (image2, im2_aligned, warp_matrix, image1.size(),cv::INTER_LINEAR + cv::WARP_INVERSE_MAP);
    
    Mat added;
    cv::add(image1, im2_aligned, added);
    Mat addedU;
    cv::add(image1, image2, addedU);
    
    cout << warp_matrix;
    
    // Show final result
//    imshow("Image 1", image1);
//    imshow("Image 2", image2);
//    imshow("Image 2 Aligned", im2_aligned);
    imshow("Added", added);
    imshow("AddedU", addedU);
//    waitKey(0);
//    destroyWindow("Image 1");
//    waitKey(0);
//    destroyWindow("Image 2");
//    waitKey(0);
//    destroyWindow("Image 2 Aligned");
    waitKey(0);
    destroyWindow("Added");
    waitKey(0);
    destroyWindow("AddedU");
}


void butterFlyTest(){

}

void surfPlusHomography(Mat img1, Mat img2){
    
    
    if( !img1.data || !img2.data )
    { std::cout<< " --(!) Error reading images " << std::endl; return; }
    
    //-- Step 1: Detect the keypoints using SURF Detector
    int minHessian = 400;
    Ptr<SURF>  detector = SURF::create(minHessian);
    std::vector<KeyPoint> keypoints_object, keypoints_scene;
    detector->detect( img1, keypoints_object );
    detector->detect( img2, keypoints_scene );
    
    //-- Draw keypoints
    //Mat img_keypoints_1; Mat img_keypoints_2;
    
    //drawKeypoints( img1, keypoints_object, img_keypoints_1, Scalar::all(-1), DrawMatchesFlags::DEFAULT );
    //drawKeypoints( img2, keypoints_scene, img_keypoints_2, Scalar::all(-1), DrawMatchesFlags::DEFAULT );
    
    //-- Show detected (drawn) keypoints
    //imshow("Keypoints 1", img1 );
    //imshow("Keypoints 2", img2 );
    
    //waitKey(0);
    
    //-- Step 2: Calculate descriptors (feature vectors)
    Ptr<SURF> extractor = SURF::create();
    Mat descriptors_object, descriptors_scene;

    extractor->compute( img1, keypoints_object, descriptors_object );
    extractor->compute( img2, keypoints_scene, descriptors_scene );
    
    //-- Step 3: Matching descriptor vectors using FLANN matcher
    FlannBasedMatcher matcher;
    std::vector< DMatch > matches;
    matcher.match( descriptors_object, descriptors_scene, matches );
    
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < descriptors_object.rows; i++ )
    { double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    
    //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
    std::vector< DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ )
    { if( matches[i].distance < 3*min_dist )
    { good_matches.push_back( matches[i]); }
    }
    
    Mat img_matches;
    drawMatches( img1, keypoints_object, img2, keypoints_scene,
                good_matches, img_matches, Scalar::all(-1), Scalar::all(-1),
                vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    
    //-- Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    
    for( int i = 0; i < 30; i++ )//good_matches.size()
    {
        //-- Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    
    Mat H = findHomography( obj, scene, CV_RANSAC );
    
    //-- Get the corners from the image_1 ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint( img1.cols, 0 );
    obj_corners[2] = cvPoint( img1.cols, img1.rows ); obj_corners[3] = cvPoint( 0, img1.rows );
    std::vector<Point2f> scene_corners(4);
    
    cout << H;
    
    perspectiveTransform( obj_corners, scene_corners, H);
    cout << scene_corners;
    cout << obj_corners;
    
    //-- Draw lines between the corners (the mapped object in the scene - image_2 )
    line( img_matches, scene_corners[0] + Point2f( img1.cols, 0), scene_corners[1] + Point2f( img1.cols, 0), Scalar(0, 255, 0), 4 );
    line( img_matches, scene_corners[1] + Point2f( img1.cols, 0), scene_corners[2] + Point2f( img1.cols, 0), Scalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[2] + Point2f( img1.cols, 0), scene_corners[3] + Point2f( img1.cols, 0), Scalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[3] + Point2f( img1.cols, 0), scene_corners[0] + Point2f( img1.cols, 0), Scalar( 0, 255, 0), 4 );
    
    //-- Show detected matches
    namedWindow("Result", CV_WINDOW_AUTOSIZE);
    imshow( "Result", img_matches );
    
    waitKey(0);
    
    destroyWindow("Result");
}
