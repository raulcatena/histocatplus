//
//  NSArray+Statistics.m
//  IMCReader
//
//  Created by Raul Catena on 9/27/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "NSArray+Statistics.h"

@implementation NSArray (Statistics)



-(float)sumOfSquares{//Array of NSValue points
    float avgX = [self meanC];
    float sumOfSquares = .0f;
    for (NSNumber *value in self) {
        sumOfSquares += pow(value.floatValue - avgX, 2.0f);
    }
    return sumOfSquares;
}

//C functions

-(float)pOfValueAtIndex:(NSInteger)index{
    if(self.count <= index)
        return .0f;
    return [[self objectAtIndex:index]floatValue]/[self sum].floatValue;
}

-(float)shannonIndex{
    float sum = .0f;
    if(self.count == 0)return sum;
    
    for (NSInteger i = 0; i < self.count; i++) {
        float pVal = [self pOfValueAtIndex:i];
        if(pVal != .0f)
            sum += pVal * log(pVal);
    }
    return -sum;
}

-(float)simpsonIndex{
    float sum = .0f;
    if(self.count == 0)return sum;
    
    for (NSInteger i = 0; i < self.count; i++) {
        NSInteger nChica = [[self objectAtIndex:i]integerValue];
        sum +=  nChica * (nChica - 1);
    }
    int nGrande = [self sumC];
    if(nGrande == 0)return .0f;
    return 1.0f - (float)sum/(nGrande * (nGrande - 1));
}

int compare (const void * a, const void * b)
{
    return ( *(int*)a - *(int*)b );
}

int median (int values[], int elements)
{
    qsort (values, elements, sizeof(int), compare);
    return values[elements/2];
}

NSInteger milenile (NSInteger values[], int elements, int milenile)
{
    if(milenile > 10000 || milenile < 0)return 0;
    qsort (values, elements, sizeof(NSInteger), compare);
    NSInteger pre = (NSInteger)elements * milenile;
    NSInteger index = pre / 10000;
    return values[index];
}

- (NSNumber *)sum {
    NSNumber *sum = [self valueForKeyPath:@"@sum.self"];
    return sum;
}

- (NSNumber *)mean {
    NSNumber *mean = [self valueForKeyPath:@"@avg.self"];
    return mean;
}

- (NSNumber *)min {
    NSNumber *min = [self valueForKeyPath:@"@min.self"];
    return min;
}

- (NSNumber *)max {
    NSNumber *max = [self valueForKeyPath:@"@max.self"];
    return max;
}

- (NSNumber *)median {
    NSArray *sortedArray = [self sortedArrayUsingSelector:@selector(compare:)];
    NSNumber *median;
    if (sortedArray.count > 2) {
        if (sortedArray.count % 2 == 0) {
            median = @(([[sortedArray objectAtIndex:sortedArray.count / 2] integerValue]) + ([[sortedArray objectAtIndex:sortedArray.count / 2 + 1] integerValue]) / 2);
        }
        else {
            median = @([[sortedArray objectAtIndex:sortedArray.count / 2] integerValue]);
        }
    }
    else {
        median = [sortedArray objectAtIndex:MAX(MIN(1, sortedArray.count/2), 0)];
    }
    return median;
}

- (int)medianC{
    int cVals[self.count];
    for (int i = 0; i <self.count; i++) {
        cVals[i] = [[self objectAtIndex:i]intValue];
    }
    return median(cVals, (int)self.count);
}

- (float)meanC{
    int val = 0;
    for (int i = 0; i <self.count; i++) {
        val += [[self objectAtIndex:i]intValue];
    }
    if(val == 0)return .0f;
    return (int)((float)val/self.count);
}

- (int)sumC{
    int val = 0;
    for (int i = 0; i <self.count; i++) {
        val += [[self objectAtIndex:i]intValue];
    }
    return val;
}

- (float)sumCFloats{
    float val = 0;
    for (int i = 0; i <self.count; i++) {
        val += [[self objectAtIndex:i]floatValue];
    }
    return val;
}

- (NSNumber *)standardDeviation {
    double sumOfDifferencesFromMean = 0;
    float meanC = [self meanC];
    for (NSNumber *score in self) {
        sumOfDifferencesFromMean += pow((score.doubleValue - meanC), 2);
    }
    
    NSNumber *standardDeviation = @(sqrt(sumOfDifferencesFromMean / self.count));
    
    return standardDeviation;
}

-(NSArray *)allStats{
    return @[[self sum], [self mean], [self median]];
}

@end
