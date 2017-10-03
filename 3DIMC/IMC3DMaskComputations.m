//
//  IMC3DMaskComputations.m
//  3DIMC
//
//  Created by Raul Catena on 10/1/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMC3DMaskComputations.h"
#import "IMC3DMask.h"

@implementation IMC3DMaskComputations

-(instancetype)initWith3DMask:(IMC3DMask *)mask{
    self = [self init];
    if(self){
        self.parent = mask;
    }
    return self;
}

@end
