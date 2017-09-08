//
//  memusage.h
//  3DIMC
//
//  Created by Raul Catena on 1/31/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    MEM_INFO_TOTAL,
    MEM_INFO_WIRED,
    MEM_INFO_ACTIVE,
    MEM_INFO_INACTIVE,
    MEM_INFO_FREE,
}MEM_INFO;

@interface memusage : NSObject

+(NSInteger)memUsage:(MEM_INFO)memInfo;
+(float)toKB:(NSInteger)bytes;
+(float)toMB:(NSInteger)bytes;
+(float)toGB:(NSInteger)bytes;

@end





