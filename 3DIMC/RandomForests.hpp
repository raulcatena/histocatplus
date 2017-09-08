//
//  RandomForests.hpp
//  IMCReader
//
//  Created by Raul Catena on 11/4/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#ifndef RandomForests_hpp
#define RandomForests_hpp

#include <stdio.h>

using namespace cv;
using namespace std;

int randomForest( int attributesPerSample, int numberOfTrainingSamples, int numberOfTestingSamples, int numberOfClasses, float *trainingData, float *testingData, float *probabilities);//Fill probabilities for each event for each class

#endif /* RandomForests_hpp */
