//
//  IMCChannelWrapper.h
//  3DIMC
//
//  Created by Raul Catena on 3/15/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCNodeWrapper;

@interface IMCChannelWrapper : NSObject

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, weak) IMCNodeWrapper *node;
@property (nonatomic, readonly) BOOL isCategorical;

@end
