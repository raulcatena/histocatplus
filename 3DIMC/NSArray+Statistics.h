//
//  NSArray+Statistics.h
//  IMCReader
//
//  Created by Raul Catena on 9/27/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Statistics)

- (float)pOfValueAtIndex:(NSInteger)index;
- (float)shannonIndex;
- (float)simpsonIndex;
- (NSNumber *)sum;
- (NSNumber *)mean;
- (NSNumber *)min;
- (NSNumber *)max;
- (NSNumber *)median;
- (NSNumber *)standardDeviation;
- (NSArray *)allStats;
- (float)sumOfSquares;

int compare (const void * a, const void * b);
int compareUInt8 (const void * a, const void * b);

NSInteger milenile (NSInteger *values, int elements, int milenile);
-(int)medianC;
-(float)meanC;
-(int)sumC;
-(float)sumCFloats;

@end
