//
//  IMCAirLabClient.h
//  3DIMC
//
//  Created by Raul Catena on 8/30/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMCImageStack;

@interface IMCAirLabClient : NSObject

+(void)getInfoClones:(NSArray<IMCImageStack *> *)stacks subdomain:(NSString *)subdomain;
+(void)getMetalForConjugates:(NSArray <IMCImageStack *>*)stacks;

@end
