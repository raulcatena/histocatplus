//
//  IMCCellDataImport.m
//  3DIMC
//
//  Created by Raul Catena on 1/31/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import "IMCCellDataImport.h"

@interface IMCCellDataImport(){
    float ** computedData;
    NSInteger cells;
    NSInteger channelCount;
    NSInteger offSet;
}
@property (nonatomic, strong) NSString *path;
@end

@implementation IMCCellDataImport

-(BOOL)allocateMemmory{
    if(channelCount > 0 && cells > 0){
        computedData = malloc(channelCount * sizeof(float *));
        for (NSInteger i = 0; i < channelCount; i++) {
            computedData[i] = malloc(cells * sizeof(float));
            if(computedData[i] == NULL)
                return NO;
        }
    }
    return YES;
}
-(float *)valuesForChannel:(NSInteger)index{
    if(index < channelCount && computedData)
        return computedData[index];
    return NULL;
}
-(NSInteger)xIndexInArray:(NSArray *)array{
    for (NSInteger i = array.count - 1; i >=0; i--) {
        NSString *str = array[i];
        if ([str isEqualToString:@"X"] || [str isEqualToString:@"avg_X"] || [str isEqualToString:@"cell_avg_X"])
            return i;
    }
    return -1;
}
-(float *)coordinates:(CellTableCoordinate)coordinate{
    NSInteger index = NSNotFound;
    NSMutableArray *possibles;
    if(coordinate == CellTableCoordinate_X) possibles = @[@"X", @"_X", @"X_",@"avg_X",@"cell_avg_X"].mutableCopy;
    if(coordinate == CellTableCoordinate_Y) possibles = @[@"X", @"_X", @"X_",@"avg_X",@"cell_avg_X"].mutableCopy;
    if(coordinate == CellTableCoordinate_Z) possibles = @[@"X", @"_X", @"X_",@"avg_X",@"cell_avg_X"].mutableCopy;
    if(coordinate == CellTableCoordinate_bh_1) possibles = @[@"bhSNE1", @"bhSNE_1", @"bh1",@"bh_1",@"tSNE1", @"tSNE_1", @"t1",@"t_1"].mutableCopy;
    if(coordinate == CellTableCoordinate_bh_1) possibles = @[@"bhSNE2", @"bhSNE_2", @"bh2",@"bh_2",@"tSNE2", @"tSNE_2", @"t2",@"t_2"].mutableCopy;
    if(coordinate == CellTableCoordinate_bh_1) possibles = @[@"bhSNE3", @"bhSNE_3", @"bh3",@"bh_3",@"tSNE3", @"tSNE_3", @"t3",@"t_3"].mutableCopy;
    
    while (possibles.count > 0 && index == NSNotFound) {
        NSString *last = [possibles lastObject];
        index = [self.channelNames indexOfObject:last];
        [possibles removeLastObject];
    }

    if(index < channelCount && computedData && index != NSNotFound)
        return computedData[index];
    return NULL;
}

-(float *)valuesForChannelWithName:(NSString *)name{
    NSInteger index = [self.channelNames indexOfObject:name];
    if(index < channelCount && computedData && index != NSNotFound)
        return computedData[index];
    return NULL;
}
-(BOOL)loadDataFromFile:(NSString *)path{
    NSData * data = [NSData dataWithContentsOfFile:path];
    BOOL success = NO;
    if(data && data.length > (sizeof(float) * 3)){//There has to be at least the cell, channel, and offset information
        for (int i = 0; i < 3; i++) {
            float value = 0;
            [data getBytes:&value range:NSMakeRange(sizeof(float) * i, sizeof(float))];
            switch (i) {
                case 0:
                    cells = (NSInteger)value;
                    break;
                case 1:
                    channelCount = (NSInteger)value;
                    break;
                case 2:
                    offSet = (NSInteger)value;
                    break;
                default:
                    break;
            }
        }
        if (offSet == (cells * channelCount + 3) * sizeof(float)) {
            if([self allocateMemmory]){
                NSString *channelsString = [[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(offSet, data.length - offSet)] encoding:NSASCIIStringEncoding];
                if(channelsString){
                    _channelNames = [channelsString componentsSeparatedByString:@"\t"];
                    if(self.channelNames.count == channelCount){
                        success = YES;
                    }
                }
            }
        }
    }
    if(!success){
        [self releaseMemory];
    }
    
    return success;
}
-(void)releaseMemory{
    if(computedData != NULL){
        for (NSInteger i = 0; i < channelCount; i++) {
            if(computedData[i] != NULL){
                free(computedData[i]);
                computedData[i] = NULL;
            }
        }
        free(computedData);
        computedData = NULL;
        channelCount = 0;
        cells = 0;
        offSet = 0;
    }
}
-(void)dealloc{
    [self releaseMemory];
}

@end
