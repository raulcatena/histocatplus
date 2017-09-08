//
//  IMCMetricsController.h
//  3DIMC
//
//  Created by Raul Catena on 6/9/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCComputationOnMask;
@class IMCWorkSpace;

@interface IMCMetricsController : NSObject<NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, weak) IMCWorkSpace * parent;

-(void)refreshTables;
-(void)addMetric;
-(void)removeMetric;

@end
