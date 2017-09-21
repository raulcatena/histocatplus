//
//  IMCPixelTraining.m
//  3DIMC
//
//  Created by Raul Catena on 2/16/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCPixelTraining.h"
#import "IMCPixelMap.h"
#import "IMCCellSegmentation.h"
#import "IMCImageStack.h"

@implementation IMCPixelTraining

-(IMCImageStack *)imageStack{
    return (IMCImageStack *)self.parent;
}
-(void)setParent:(IMCNodeWrapper *)parent{
    if(parent){
        if(!parent.jsonDictionary[JSON_DICT_PIXEL_TRAININGS])
            parent.jsonDictionary[JSON_DICT_PIXEL_TRAININGS] = @[].mutableCopy;
        if(![parent.jsonDictionary[JSON_DICT_PIXEL_TRAININGS] containsObject:self.jsonDictionary])
            [parent.jsonDictionary[JSON_DICT_PIXEL_TRAININGS] addObject:self.jsonDictionary];
    }
    [super setParent:parent];
}
-(NSString *)itemSubName{
    return [@"training_" stringByAppendingString:self.imageStack.itemName?self.imageStack.itemName:@""];
}

-(NSArray *)trainingLabels{
    return self.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LABELS];
}

-(NSArray *)learningSettings{
    return self.jsonDictionary[JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS];
}

-(BOOL)isSegmentation{
    return [self.jsonDictionary[JSON_DICT_PIXEL_TRAINING_IS_SEGMENTATION]boolValue];
}
-(IMCPixelMap *)whichMap{
    for (IMCPixelMap *map in self.imageStack.pixelMaps)
        if(map.whichTraining == self)
            return map;
    return nil;
}


-(instancetype)initWithPixelTraining:(UInt8 *)trainingBuffer labels:(NSDictionary *)dictionary andParent:(IMCImageStack *)stack{
    self = [self init];
    if(self){
        //Create jsonDictionary and add it to jsondict of stack
        //Create image and save it
        //Create a training hash
    }
    return self;
}

-(void)loadLayerDataWithBlock:(void (^)())block{

    [self loadBuffer];
    
    IMCPixelClassificationTool *tool;
    if(self.isSegmentation)
        tool = [[IMCCellSegmentation alloc]initWithStack:self.imageStack andTraining:self];
    else
        tool = [[IMCPixelClassificationTool alloc]initWithStack:self.imageStack andTraining:self];
    
    [[tool window] makeKeyAndOrderFront:tool];
    [super loadLayerDataWithBlock:block];    

}
-(void)loadBuffer{
    
    NSString *path = [self.imageStack.baseDirectoryPath stringByAppendingPathComponent:self.relativePath];
    NSImage *image = [[NSImage alloc]initWithData:[NSData dataWithContentsOfFile:path]];
    
    if(!self.imageStack.isLoaded)
        [self.imageStack loadLayerDataWithBlock:nil];
    while(!self.imageStack.isLoaded);
    NSInteger pix = self.imageStack.numberOfPixels;
    self.trainingBuffer = (UInt8 *)calloc(pix, sizeof(UInt8));
    if(image){
        NSBitmapImageRep *rep = (NSBitmapImageRep *)image.representations.firstObject;
        UInt8 *data = (UInt8 *)[rep bitmapData];

        for (NSInteger i = 0; i < pix; i++)
            self.trainingBuffer[i] = data[i];
        self.isLoaded = YES;
    }
}

-(void)unLoadLayerDataWithBlock:(void (^)())block{
    if(_trainingBuffer){
        free(_trainingBuffer);
        _trainingBuffer = NULL;
    }
    [super unLoadLayerDataWithBlock:block];
}

-(void)dealloc{
    if(_trainingBuffer)
        free(_trainingBuffer);
}

@end
