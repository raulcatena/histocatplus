//
//  RandomForests.cpp
//  IMCReader
//
//  Created by Raul Catena on 11/4/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

//Adapated from
//http://breckon.eu/toby/teaching/ml/examples/c++/opticaldigits_ex/randomforest.cpp

#include "RandomForests.hpp"


int read_data_from_float_array(float *float_data, Mat data, Mat classes,
                       int n_samples, int attributesPerSample )
{
    
    for(int line = 0; line < n_samples; line++){
        for(int attribute = 0; attribute < attributesPerSample; attribute++)
            data.at<float>(line, attribute) = float_data[line * (attributesPerSample + 1) + attribute];
        classes.at<float>(line, 0) = float_data[line * (attributesPerSample + 1) + attributesPerSample];
    }
    
    
    
    return 1; // all OK
}


/******************************************************************************/

int randomForest( int attributesPerSample, int numberOfTrainingSamples, int numberOfTestingSamples, int numberOfClasses, float *trainingData, float *testingData, float *probabilities)
{
    // lets just check the version first
    
    printf ("OpenCV version %s (%d.%d.%d)\n",
            CV_VERSION,
            CV_MAJOR_VERSION, CV_MINOR_VERSION, CV_SUBMINOR_VERSION);
    
    // define training data storage matrices (one for attribute examples, one
    // for classifications)
    Mat training_data = Mat(numberOfTrainingSamples, attributesPerSample, CV_32FC1);
    Mat training_classifications = Mat(numberOfTrainingSamples, 1, CV_32FC1);
    
    //define testing data storage matrices
    Mat testing_data = Mat(numberOfTestingSamples, attributesPerSample, CV_32FC1);
    Mat testing_classifications = Mat(numberOfTestingSamples, 1, CV_32FC1);
    
    // define all the attributes as numerical
    // alternatives are CV_VAR_CATEGORICAL or CV_VAR_ORDERED(=CV_VAR_NUMERICAL)
    // that can be assigned on a per attribute basis
    
    Mat var_type = Mat(attributesPerSample + 1, 1, CV_8U );
    var_type.setTo(Scalar(cv::ml::VAR_NUMERICAL) ); // all inputs are numerical
    
    // this is a classification problem (i.e. predict a discrete number of class
    // outputs) so reset the last (+1) output var_type element to CV_VAR_CATEGORICAL
    
    var_type.at<uchar>(attributesPerSample, 0) = cv::ml::VAR_CATEGORICAL;//CV_VAR_NUMERICAL;//CV_VAR_ORDERED;//CV_VAR_CATEGORICAL;
    
    double result; // value returned from a prediction
    
    // load training and testing data sets
    
    if (read_data_from_float_array(trainingData, training_data, training_classifications, numberOfTrainingSamples, attributesPerSample) &&
        read_data_from_float_array(testingData, testing_data, testing_classifications, numberOfTestingSamples, attributesPerSample))
    {
        //define the parameters for training the random forest (trees)
        //float * priors = (float *)calloc(numberOfClasses, sizeof(float));
        //for(int i = 0; i < numberOfClasses; i++)priors[i] = 1.0f;// weights of each classification for classes
        //for(int i = 0; i < numberOfClasses; i++)printf("%f ",priors[i]);
        
        //Mat priorsMat = Mat(cv::Size(1, numberOfClasses), CV_32F, priors);
        //int cycles = 10;
        
        //int sectorSize = MAX(1, numberOfTrainingSamples/cycles);
        //cout << endl << sectorSize << " sector size" << endl;
        
        auto rtrees = cv::ml::RTrees::create();
        rtrees->setMaxDepth(10);
        rtrees->setMinSampleCount(2);
        rtrees->setRegressionAccuracy(0);
        rtrees->setUseSurrogates(false);
        rtrees->setMaxCategories(numberOfClasses);
        //rtrees->setPriors(priorsMat);
        rtrees->setCalculateVarImportance(true);
        rtrees->setActiveVarCount(MAX(ceilf(sqrt(attributesPerSample)), 2));
        rtrees->setTermCriteria({ cv::TermCriteria::MAX_ITER, 100, 0 });
        
        
        Ptr<cv::ml::TrainData> tran = cv::ml::TrainData::create(training_data, cv::ml::ROW_SAMPLE, training_classifications, cv::noArray(), cv::noArray(), cv::noArray(), var_type);
        
        rtrees->train(tran);
        
        Mat test_sample;
        
        printf("%f error", rtrees->calcError(tran, false, cv::noArray()));
        
        
        for (int tsample = 0; tsample < numberOfTestingSamples; tsample++)
        {
            
            // extract a row from the testing matrix
            test_sample = testing_data.row(tsample);
            // run random forest prediction
            
            result = rtrees->predict(test_sample);
            testingData[tsample * (attributesPerSample + 1) + attributesPerSample] = (float)result;
            //Add proportion values. Without accounting for group numbers
//            for(int i = 0; i < numberOfClasses; i++)
//                if(i == result -1)
//                    probabilities[tsample * numberOfClasses + i] += 1.0f;
        }
        return 0;
    }
    
    // not OK : main returns -1
    
    return -1;
}