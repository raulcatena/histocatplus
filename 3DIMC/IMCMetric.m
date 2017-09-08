//
//  IMCMetric.m
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMetric.h"

@implementation IMCMetric

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self = [super init];
    if(self){
        self.metricType = dictionary[JSON_METRIC_TYPE];
        self.name = dictionary[JSON_METRIC_NAME];
        self.itemHash = dictionary[JSON_METRIC_HASH];
        self.primaryChannels = dictionary[JSON_METRIC_CHANNELS];
        self.filterChannels = dictionary[JSON_METRIC_FILTERS];
        self.isAndFiltering = [dictionary[JSON_METRIC_AND_FILTER] boolValue];
    }
    return self;
}

-(NSMutableArray *)arrayFromIndexSet:(NSIndexSet *)set{
    NSMutableArray *array = @[].mutableCopy;
    [set enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        [array addObject:@(index)];
    }];
    return array;
}

-(instancetype)initWithMetricType:(NSString *)type name:(NSString *)name primaryChannels:(NSIndexSet *)primaryChannels filterChannels:(NSIndexSet *)filterChannels isAnd:(BOOL)isAnd{
    self = [super init];
    if(self){
        self.metricType = type;
        self.name = name;
        self.itemHash = [IMCUtils randomStringOfLength:13];
        self.primaryChannels = [self arrayFromIndexSet:primaryChannels];
        self.filterChannels = [self arrayFromIndexSet:filterChannels];
        self.isAndFiltering = isAnd;
    }
    return self;
}
-(NSMutableDictionary *)generateDictionary{
    return @{
             JSON_METRIC_TYPE: self.metricType,
             JSON_METRIC_NAME: self.name,
             JSON_METRIC_HASH: self.itemHash,
             JSON_METRIC_CHANNELS: self.primaryChannels,
             JSON_METRIC_FILTERS: self.filterChannels,
             JSON_METRIC_AND_FILTER: @(self.isAndFiltering)
             }.mutableCopy;
}
+(NSArray *)allOptions{
    return @[@"Option A", @"Option B"];
}
@end
