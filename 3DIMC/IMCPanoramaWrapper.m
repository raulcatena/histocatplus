//
//  IMCPanoramaWrapper.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"

@interface IMCNodeWrapper(){
    
}

@end

@implementation IMCPanoramaWrapper


-(NSString *)itemName{
    if(self.isPanorama)return self.panoramaName;
    return [super itemName]?[super itemName]:@"Image w/o panorama";
}
-(NSString *)itemSubName{
    return @"";
}

#pragma mark getters

-(BOOL)isPanorama{
    return [[self.jsonDictionary valueForKey:JSON_DICT_CONT_IS_PANORAMA]boolValue];
}

-(NSString *)panoramaName{
    if(![self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_NAME])return @"Panorama";
    return [self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_NAME];
}

-(float)widthPanorama{
    return [[self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_W]floatValue];
}

-(float)heightPanorama{
    return [[self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_H]floatValue];
}

-(NSMutableArray *)images{
    if(![self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_IMAGES])
        [self.jsonDictionary setValue:@[].mutableCopy forKey:JSON_DICT_CONT_PANORAMA_IMAGES];
    return [self.jsonDictionary valueForKey:JSON_DICT_CONT_PANORAMA_IMAGES];
}

-(NSImage *)panoramaImage{
    return self.after == YES ? _afterPanoramaImage : _panoramaImage;
}

#pragma mark others

-(void)addRoiRectangleForStack:(IMCImageStack *)stack{
    
    
}

-(void)loadLayerDataWithBlock:(void (^)(void))block{
    if(![self canLoad])return;
    self.isLoaded = YES;
    [self.parent loadLayerDataWithBlock:block];
}
-(void)unLoadLayerDataWithBlock:(void (^)(void))block{
    self.isLoaded = NO;
    for(IMCImageStack *child in self.children)
        [child unLoadLayerDataWithBlock:nil];
    self.panoramaImage = nil;
    self.afterPanoramaImage = nil;
    [super unLoadLayerDataWithBlock:block];
}

@end
