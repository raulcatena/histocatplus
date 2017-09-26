//
//  IMC3DMask.m
//  3DIMC
//
//  Created by Raul Catena on 9/26/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMC3DMask.h"
#import "IMCLoader.h"

@implementation IMC3DMask

-(instancetype)initWithLoader:(IMCLoader *)loader{
    self = [self init];
    if(self)
        self.coordinator = loader;
    return self;
}

-(NSArray *)components{
    return self.jsonDictionary[JSON_DICT_3DS_COMPONENTS];
}
-(void)setTheComponents:(NSArray *)components{
    self.jsonDictionary[JSON_DICT_3DS_COMPONENTS] = components;
}
-(NSMutableDictionary *)metadata{
    if(!self.jsonDictionary[JSON_DICT_3DS_METADATA])
        self.jsonDictionary[JSON_DICT_3DS_METADATA] = @{}.mutableCopy;
    return self.jsonDictionary[JSON_DICT_3DS_METADATA];
}
-(Mask3D_Type)type{
    return (Mask3D_Type)[self.metadata[JSON_DICT_3DS_METADATA_TYPE]integerValue];
}
-(void)setType:(Mask3D_Type)type{
    self.metadata[JSON_DICT_3DS_METADATA_TYPE] = @(type);
}
-(NSInteger)channel{
    return [self.metadata[JSON_DICT_3DS_METADATA_CHANNEL]integerValue];
}
-(void)setChannel:(NSInteger)channel{

}
-(NSInteger)expansion{
    return [self.metadata[JSON_DICT_3DS_METADATA_EXPANSION]integerValue];
}
-(void)setExpansion:(NSInteger)expansion{
    self.metadata[JSON_DICT_3DS_METADATA_EXPANSION] = @(expansion);
}
-(float)threshold{
    return [self.metadata[JSON_DICT_3DS_METADATA_THRESHOLD]floatValue];
}
-(void)setThreshold:(float)threshold{
    self.metadata[JSON_DICT_3DS_METADATA_THRESHOLD] = @(threshold);
}
-(NSInteger)minKernel{
    return [self.metadata[JSON_DICT_3DS_METADATA_MIN_KERNEL]integerValue];
}
-(void)setMinKernel:(NSInteger)minKernel{
    self.metadata[JSON_DICT_3DS_METADATA_MIN_KERNEL] = @(minKernel);
}
-(BOOL)sheepShaver{
    return [self.metadata[JSON_DICT_3DS_METADATA_SHEEP_SHAVER]boolValue];
}
-(void)setSheepShaver:(BOOL)sheepShaver{
    self.metadata[JSON_DICT_3DS_METADATA_MIN_KERNEL] = @(sheepShaver);
}
-(void)loadLayerDataWithBlock:(void (^)())block{

}
-(void)unLoadLayerDataWithBlock:(void (^)())block{

}

@end
