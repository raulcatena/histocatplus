//
//  IMCTransformDictController.m
//  3DIMC
//
//  Created by Raul Catena on 1/30/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCTransformDictController.h"

@implementation IMCTransformDictController

-(void)changedCoarse:(NSSegmentedControl *)sender{
    self.angle.increment = .1f * pow(10, sender.selectedSegment);
    self.offsetX.increment = .1f * pow(10, sender.selectedSegment);
    self.offsetY.increment = .1f * pow(10, sender.selectedSegment);
    self.compresionX.increment = .001f * pow(10, sender.selectedSegment);
    self.compresionY.increment = .001f * pow(10, sender.selectedSegment);
}

-(void)syncAll:(id)sender{
    if(sender == self.angle)
        self.angleField.stringValue = [NSString stringWithFormat:@"%.2f", self.angle.floatValue];
    if(sender == self.offsetX)
        self.offsetXField.stringValue = [NSString stringWithFormat:@"%.2f", self.offsetX.floatValue];
    if(sender == self.offsetY)
        self.offsetYField.stringValue = [NSString stringWithFormat:@"%.2f", self.offsetY.floatValue];
    if(sender == self.compresionX)
        self.compresionXField.stringValue = [NSString stringWithFormat:@"%.3f", self.compresionX.floatValue];
    if(sender == self.compresionY)
        self.compresionYField.stringValue = [NSString stringWithFormat:@"%.3f", self.compresionY.floatValue];
    
    if(sender == self.angleField && !isnan(self.angleField.floatValue))
        self.angle.floatValue = self.angleField.floatValue;
    if(sender == self.offsetXField && !isnan(self.offsetXField.floatValue))
        self.offsetX.floatValue = self.offsetXField.floatValue;
    if(sender == self.offsetYField && !isnan(self.offsetYField.floatValue))
        self.offsetY.floatValue = self.offsetYField.floatValue;
    if(sender == self.compresionXField && !isnan(self.compresionXField.floatValue))
        self.compresionX.floatValue = self.compresionXField.floatValue;
    if(sender == self.compresionYField && !isnan(self.compresionYField.floatValue))
        self.compresionY.floatValue = self.compresionYField.floatValue;
}

-(void)updateFromDict{
    self.angle.floatValue = [self.transformDict[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue];
    self.offsetX.floatValue = [self.transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue];
    self.offsetY.floatValue = [self.transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue];
    self.compresionX.floatValue = [self.transformDict[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
    self.compresionY.floatValue = [self.transformDict[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
    [self syncAll:self.angle];
    [self syncAll:self.offsetX];
    [self syncAll:self.offsetY];
    [self syncAll:self.compresionX];
    [self syncAll:self.compresionY];
}

-(void)setTransformDict:(NSMutableDictionary *)transformDict{
    _transformDict = transformDict;
    [self updateFromDict];
}

-(void)refresh:(id)sender{
    
    [self syncAll:sender];
    
    self.transformDict[JSON_DICT_IMAGE_TRANSFORM_ROTATION] = @(self.angle.floatValue);
    self.transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X] = @(self.offsetX.floatValue);
    self.transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y] = @(self.offsetY.floatValue);
    self.transformDict[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X] = @(self.compresionX.floatValue);
    self.transformDict[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y] = @(self.compresionY.floatValue);
    
    [self.delegate refresh];
}

@end
