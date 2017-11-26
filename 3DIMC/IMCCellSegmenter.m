//
//  IMCCellSegmenter.m
//  3DIMC
//
//  Created by Raul Catena on 3/6/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellSegmenter.h"
#import "IMCImageStack.h"

@implementation IMCCellSegmenter


+(void)saveCellProfilerPipelineWithImageWithWf:(NSString *)wf hash:(NSString *)hash minCellDiam:(NSString *)minCellDiam maxCellDiam:(NSString *)maxCellDiam lowThreshold:(NSString *)lowerThreshold upperThreshold:(NSString *)upperThreshold showIntermediate:(BOOL)showInter foreGround:(BOOL)foreground{
    
    NSString *pathImage = [NSString stringWithFormat:@"%@/%@_seg_pmap.tiff", wf, hash];
    NSLog(@"Path image %@", pathImage);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:pathImage isDirectory:NO])return;
    
    NSString *pathTemplate = [[NSBundle mainBundle]pathForResource:@"cp_pmaps_only_mask_temp" ofType:nil];//Will choose from dynamic
    NSString *temp = [[NSString alloc]initWithContentsOfFile:pathTemplate encoding:NSUTF8StringEncoding error:NULL];
    
    pathImage = [pathImage stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{file_url}}" withString:pathImage];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{prefix}}" withString:hash];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{min_nuc_size}}" withString:minCellDiam];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{max_nuc_size}}" withString:maxCellDiam];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{lower_threshold}}" withString:lowerThreshold];
    temp = [temp stringByReplacingOccurrencesOfString:@"{{upper_threshold}}" withString:upperThreshold];
    
    if(showInter || !foreground)
        temp = [temp stringByReplacingOccurrencesOfString:@"show_window:True" withString:@"show_window:False"];
    
    NSString *path = [NSString stringWithFormat:@"%@/%@_cp_pipeline_prob.cppipe", wf, hash];
    NSLog(@"path %@", path);
    [temp writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

+(void)runCPSegmentationForeGround:(BOOL)foreground details:(BOOL)details onStack:(IMCImageStack *)stack withHash:(NSString *)hash withBlock:(void(^)())block inOwnThread:(BOOL)ownThread{
    NSString *pathCP = [[NSUserDefaults standardUserDefaults]valueForKey:PREF_LOCATION_DRIVE_CP];//[[NSBundle mainBundle]pathForResource:@"CellProfiler" ofType:@"app"];
    if(!pathCP || ![pathCP containsString:@"CellProfiler"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [General runAlertModalWithMessage:@"Go to preferences and set Cell Profiler's location in your drive"];
        });
        return;
    }
    pathCP = [pathCP stringByAppendingString:@"/Contents/MacOS/CellProfiler"];
    
    NSString *pathCPPipe = [NSString stringWithFormat:@"%@/%@_cp_pipeline_prob.cppipe", [stack.fileWrapper workingFolder], hash.copy];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:pathCPPipe isDirectory:NO])return;
    
    NSMutableArray *args = [NSMutableArray array];
    if(foreground == NO)[args addObject:@"-c"];
    [args addObject:@"-r"];
    [args addObject:@"-p"];
    [args addObject:pathCPPipe];
    [args addObject:@"-i"];
    [args addObject:[stack.fileWrapper workingFolder]];
    [args addObject:@"-o"];
    [args addObject:[stack.fileWrapper workingFolder]];
    
    if(ownThread){
            dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
            dispatch_async(aQ, ^{
                [[NSTask launchedTaskWithLaunchPath:pathCP arguments:[NSArray arrayWithArray:args]]waitUntilExit];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(block)block();
                });
            });
    }else{
        [[NSTask launchedTaskWithLaunchPath:pathCP arguments:[NSArray arrayWithArray:args]]waitUntilExit];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block)block();
        });
    }
    

}

@end
