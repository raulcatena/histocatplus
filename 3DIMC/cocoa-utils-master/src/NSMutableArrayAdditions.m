/*
 * Copyright 2008 Stefan Arentz <stefan@arentz.nl>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "NSMutableArrayAdditions.h"

@implementation NSMutableArray (MutableArrayAdditions)

- (NSMutableArray*)  shuffle
{
   NSUInteger n = [self count];
   while (n > 1) {
      NSUInteger k = rand() % n;
      n--;
      [self exchangeObjectAtIndex: n withObjectAtIndex: k];
   }

   return self;
}

-(NSArray *)filterClass:(NSString *)class{
    NSMutableArray *result = @[].mutableCopy;
    [self enumerateObjectsUsingBlock:^(id test, NSUInteger idx, BOOL *stop){
        if([test isMemberOfClass:NSClassFromString(class)])[result addObject:test];
    }];
    return [NSArray arrayWithArray:result];
}

@end

