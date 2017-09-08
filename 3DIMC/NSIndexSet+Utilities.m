//
//  NSIndexSet+Utilities.m
//  3DIMC
//
//  Created by Raul Catena on 6/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "NSIndexSet+Utilities.h"

@implementation NSIndexSet (Utilities)

- (NSUInteger)indexAtIndex:(NSUInteger)anIndex
{
    if (anIndex >= [self count])
        return NSNotFound;
    
    NSUInteger index = [self firstIndex];
    for (NSUInteger i = 0; i < anIndex; i++)
        index = [self indexGreaterThanIndex:index];
    return index;
}

@end
