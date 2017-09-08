//
//  IMCAirLabClient.m
//  3DIMC
//
//  Created by Raul Catena on 8/30/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCAirLabClient.h"
#import "IMCImageStack.h"

@implementation IMCAirLabClient

+(void)getInfoClones:(NSArray <IMCImageStack *>*)stacks{
    __block int counter = 0;
    
    NSMutableDictionary *collect = @{}.mutableCopy;
    for (IMCImageStack *stack in stacks) {
        for (NSString *string in stack.origChannels) {
            //Avoid passing raw numbered channels
            if([string rangeOfString:@"("].location == NSNotFound)continue;
            if([string rangeOfString:@")"].location == NSNotFound)continue;
            
            NSString *stringB = [string stringByReplacingOccurrencesOfString:@" (" withString:@"("];
            NSString *idClone = [[[[stringB componentsSeparatedByString:@"_"]lastObject]componentsSeparatedByString:@"("]firstObject];
            //[collect setObject:@[string].mutableCopy forKey:idClone];
            NSMutableArray *prev = collect[idClone];
            if(!prev){
                prev = @[].mutableCopy;
                [collect setObject:prev forKey:idClone];
            }
            [prev addObject:@{[NSNumber numberWithInteger:[stack.origChannels indexOfObject:string]]: stack}];
        
        }
    }
    
    NSString *arg = [collect.allKeys componentsJoinedByString:@","];
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:
                               [NSString stringWithFormat:@"https://airlab-1118.appspot.com/apiLabPad/api/getInfoForClones/%@", arg]]
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){
            counter++;
            
            if (data) {
                NSArray *infoClones =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                if(infoClones){
                    
                    for (NSDictionary *infoClone in infoClones) {
                        NSString *cloneId = [infoClone valueForKey:@"cloCloneId"];
                        
                        NSString *nameProt;
                        if([infoClone valueForKey:@"proName"])nameProt = [infoClone valueForKey:@"proName"];
                        
                        if ([[infoClone valueForKey:@"cloIsPhospho"]intValue] == 1 && nameProt) {
                            nameProt = [@"p" stringByAppendingString:nameProt];
                        }
                        if(nameProt){
                            NSArray *itemsToChange = collect[cloneId];
                            for (NSDictionary *item in itemsToChange) {
                                NSInteger index = [item.allKeys.firstObject integerValue];
                                IMCImageStack *stack = item.allValues.firstObject;
                                if(stack.channels.count >= index - 1){
                                    [stack.channels replaceObjectAtIndex:index withObject:nameProt.copy];
                                }
                            };
                        }
                    }
                }
            }
    }]resume];
}



+(void)getMetalForConjugates:(NSArray <IMCImageStack *>*)stacks{
    __block int counter = 0;
    
    
    NSMutableDictionary *collect = @{}.mutableCopy;
    for (IMCImageStack *stack in stacks) {
        for (NSString *string in stack.origChannels) {
            NSString *stringB = [string stringByReplacingOccurrencesOfString:@" (" withString:@"("];
            NSString *idClone = [[[[stringB componentsSeparatedByString:@"(("]lastObject]componentsSeparatedByString:@"))"]firstObject];
            [collect setObject:@[string].mutableCopy forKey:idClone];
        }
    }
    
    NSString *arg = [collect.allKeys componentsJoinedByString:@","];
    
    NSLog(@"Args %@", arg);
    
//    NSURLSession *session = [NSURLSession sharedSession];
//    [[session dataTaskWithURL:[NSURL URLWithString:
//                               [NSString stringWithFormat:@"https://airlab-1118.appspot.com/apiLabPad/api/getInfoForClones/%@", arg]]
//            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error){}];
    
    NSMutableURLRequest *req = [NSMutableURLRequest
                                requestWithURL:
                                [NSURL URLWithString:
                                 [NSString stringWithFormat:@"https://airlab-1118.appspot.com/apiLabPad/api/getInfoForConjugates/%@", arg]]];
    
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        counter++;
        
        if (data) {
            NSArray *infoConjs =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSLog(@"Info Conjugates %@", infoConjs);
            //            if(infoClones){
            //                NSMutableArray *copyChannels = self.channels.mutableCopy;
            //                for (NSDictionary *infoClone in infoClones) {
            //                    if(infoClone == 0)continue;
            //                    NSString *nameProt;
            //                    if([infoClone valueForKey:@"proName"])nameProt = [infoClone valueForKey:@"proName"];
            //
            //                    if ([[infoClone valueForKey:@"cloIsPhospho"]intValue] == 1 && nameProt) {
            //                        nameProt = [@"p" stringByAppendingString:nameProt];
            //                    }
            //                    if (nameProt) {
            //                        [[cleanStrings valueForKey:[infoClone valueForKey:@"cloCloneId"]]addObject:nameProt];
            //
            //                        NSInteger index = [self.originalChannels indexOfObjectIdenticalTo:[[cleanStrings valueForKey:[infoClone valueForKey:@"cloCloneId"]]firstObject]];
            //                        [copyChannels removeObjectAtIndex:index];
            //                        [copyChannels insertObject:nameProt atIndex:index];
            //                    }
            //                }
            //                self.channels = [NSArray arrayWithArray:copyChannels];
            //            }
        }
    }];
}

@end
