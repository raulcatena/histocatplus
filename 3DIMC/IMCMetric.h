//
//  IMCMetric.h
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface IMCMetric : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *itemHash;
@property (nonatomic, strong) NSString *metricType;
@property (nonatomic, strong) NSMutableArray *primaryChannels;
@property (nonatomic, strong) NSMutableArray *filterChannels;
@property (nonatomic, assign) BOOL isAndFiltering;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;
-(instancetype)initWithMetricType:(NSString *)type name:(NSString *)name primaryChannels:(NSIndexSet *)primaryChannels filterChannels:(NSIndexSet *)filterChannels isAnd:(BOOL)isAnd;
-(NSMutableDictionary *)generateDictionary;
+(NSArray *)allOptions;

@end
