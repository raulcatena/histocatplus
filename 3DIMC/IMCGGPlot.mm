//
//  IMCGGPlot.m
//  3DIMC
//
//  Created by Raul Catena on 2/24/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCGGPlot.h"
#import "IMCComputationOnMask.h"
#import "NSColor+Utilities.h"
#import "IMCChannelWrapper.h"

@implementation IMCGGPlot

#define QUOTE(...) #__VA_ARGS__


#define PATH_R @"/Library/Frameworks/R.framework/Resources/Rscript"
#define PATH_R_INTERNAL_EXTENSION @"/Resources/Rscript"
#define PATH_R_EXTENSION @"/Resources/Rscript"

#define PATH_TEMP_PLACEHOLDER @"{{}}"

#define PATH_COMP_DATA @"temp_data_imc.cbin"
#define PATH_COMP_CHANNELS @"temp_channs_imc.txt"
#define PATH_COMP_SCRIPT @"temp_script_imc.R"
#define PATH_COMP_SCRIPT_EXT @"txt"
#define PATH_COMP_RESULT_IMAGE @"temp_result_imc.png"

#define GEOM_TYPE @"{{geom_type}}"
#define EVENTS_PLACEHOLDER @"{{events}}"
#define CHANCOUNT_PLACEHOLDER @"{{channels}}"
#define VAR_X_GGPLOT @"{{x_ggplot}}"
#define VAR_Y_GGPLOT @"{{y_ggplot}}"
#define X_CHANNEL @"{{x_channel}}"
#define Y_CHANNEL @"{{y_channel}}"
#define C_CHANNEL @"{{c_channel}}"
#define S_CHANNEL @"{{s_channel}}"
#define VAR_COLOR_GGPLOT @"{{color_ggplot}}"
#define VAR_SHAPE_GGPLOT @"{{shape_ggplot}}"
#define VAR_FACET_GGPLOT @"{{facet}}"
#define LEGEND_TITLE @"{{legend_title}}"
#define SIZE_GPOINT @"{{size_geomp}}"
#define ALPHA_GPOINT @"{{alpha_geomp}}"
#define COLOR_GPOINT @"{{color_gpoint}}"


-(NSString *)getTempPathResultPath{
    NSLog(@"%@", NSTemporaryDirectory());
    return [NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_RESULT_IMAGE];
}

-(NSString *)getTempScriptPath{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_SCRIPT];
}

-(void)logError:(NSError *)error{
    if(error)
        NSLog(@"%@ - %@ - %@", error, error.userInfo, error.localizedDescription);
}

-(void)prepareData:(float **)bindata channels:(NSArray *)channels events:(NSInteger)events{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_DATA];
    NSMutableData *data = [NSMutableData data];
    for (NSInteger i = 0; i < channels.count; i++) {
        [data appendBytes:bindata[i] length:events * sizeof(float)];
    }
    NSError *error = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    [self logError:error];
    
    NSString * channs = [channels componentsJoinedByString:@"\t"];
    channs = [channs stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    [self logError:error];
    
    [channs writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_CHANNELS] atomically:YES encoding:NSUTF8StringEncoding error:&error];
}




-(void)prepareDataMultiImage:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray<IMCChannelWrapper *> *)channels{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_DATA];
    
    NSMutableData *data = [NSMutableData data];
    NSInteger maxChannels = 0;
    IMCComputationOnMask *exampleWithMax;
    
    //Add the file Id. Will be the first column in R dataframe
    //Since I loop, I take computation with greater number of channels for safety
    for(IMCComputationOnMask *comp in computations){

        float index = (float)([computations indexOfObject:comp] + 1);
        float * sample = (float *)calloc(comp.segmentedUnits, sizeof(float));
        for(NSInteger l = 0; l < comp.segmentedUnits; l++)sample[l] = index;
        [data appendBytes:sample length:comp.segmentedUnits * sizeof(float)];
        free(sample);
        
        if(comp.channels.count >maxChannels){
            maxChannels = comp.channels.count;
            exampleWithMax = comp;
        }
    }
    
    for (IMCChannelWrapper *num in channels) {
        for(IMCComputationOnMask *comp in computations)
            if(comp.channels.count <= num.index){//Fill with zeroes
                float * bytes = (float *)calloc(comp.segmentedUnits, sizeof(float));
                [data appendBytes:bytes length:comp.segmentedUnits * sizeof(float)];
                free(bytes);
            }
            else
                [data appendBytes:comp.computedData[num.index] length:comp.segmentedUnits * sizeof(float)];
        
    }
    
    NSError *error = nil;
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    [self logError:error];

    NSMutableArray *channsArr = @[@"CompId"].mutableCopy;
    for (IMCChannelWrapper *num in channels) {
        [channsArr addObject:exampleWithMax.channels[num.index]];
    }
    
    NSString * channs = [channsArr componentsJoinedByString:@"\t"];
    channs = [channs stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    [self logError:error];
    
    [channs writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:PATH_COMP_CHANNELS] atomically:YES encoding:NSUTF8StringEncoding error:&error];
}

-(NSString *)scatterPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
    
    return [self rScriptWithPlotType:@"geom_point" WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
    
}

-(NSString *)boxPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
    
    return [self rScriptWithPlotType:@"geom_boxplot" WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
    
}

-(NSString *)histogramPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
    
    return [self rScriptWithPlotType:@"geom_bar" WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
}

-(NSString *)linePlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
    
    return [self rScriptWithPlotType:@"geom_density" WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
}

-(NSString *)heatMapPlotWithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
    
    return [self rScriptWithPlotType:@"geom_tile" WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
}

-(NSString *)rScriptWithPlotType:(NSString *)plotType WithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{

    NSString *path = [[NSBundle mainBundle]pathForResource:@"scatter" ofType:PATH_COMP_SCRIPT_EXT];
    
    NSError *error;
    NSString *templateFile = [[NSString alloc]initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    [self logError:error];
    
    templateFile = [templateFile stringByReplacingOccurrencesOfString:PATH_TEMP_PLACEHOLDER withString:NSTemporaryDirectory()];
    
    
    //Passing event number
    NSInteger events = 0;
    for (IMCComputationOnMask *comp in computations)
        events += comp.segmentedUnits;
    templateFile = [templateFile stringByReplacingOccurrencesOfString:EVENTS_PLACEHOLDER withString:[NSString stringWithFormat:@"%li", events]];
    
    //Passing channel number
    templateFile = [templateFile stringByReplacingOccurrencesOfString:CHANCOUNT_PLACEHOLDER withString:[NSString stringWithFormat:@"%li", inOrderChannels.count + 1]];
    
    //Passing Plot Type
    templateFile = [templateFile stringByReplacingOccurrencesOfString:GEOM_TYPE withString:plotType];
    
    //Passing color (Will be overriden if there is colorscale
    templateFile = [templateFile stringByReplacingOccurrencesOfString:COLOR_GPOINT withString:c == 0?
                    [NSString stringWithFormat:@"color = '#%@'", [colorPoints hexEncoding]]:@""];
    
    //X log
    NSString *transf = [NSString stringWithFormat:@"df[%li]", x];
    if(xMode == 1)transf = [NSString stringWithFormat:@"log(%@)", transf.copy];
    if(xMode == 2)transf = [NSString stringWithFormat:@"asinh(%@/5)", transf.copy];
    
    //X
    if(x > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_X_GGPLOT withString:
                        ([plotType isEqualToString:@"geom_bar"] || [plotType  isEqualToString:@"geom_boxplot"] || [plotType  isEqualToString:@"geom_tile"])?
                        [NSString stringWithFormat:@"x = as.factor(df[[%li]])", x]:
                        [NSString stringWithFormat:@"x = %@", transf.copy]];
    else
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_X_GGPLOT withString:@""];
    
    templateFile = [templateFile stringByReplacingOccurrencesOfString:X_CHANNEL withString:[NSString stringWithFormat:@"%li", x]];
    
    //Y log
    transf = [NSString stringWithFormat:@"df[%li]", y];
    if(yMode == 1)transf = [NSString stringWithFormat:@"log(%@)", transf.copy];
    if(yMode == 2)transf = [NSString stringWithFormat:@"asinh(%@/5)", transf.copy];
    //Y
    if(y > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_Y_GGPLOT withString:
                        [plotType  isEqualToString:@"geom_tile"]?
                        [NSString stringWithFormat:@", y = as.factor(df[[%li]])", y]:
                        [NSString stringWithFormat:@", y = %@", transf.copy]];
    else
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_Y_GGPLOT withString:@""];
    
    templateFile = [templateFile stringByReplacingOccurrencesOfString:Y_CHANNEL withString:[NSString stringWithFormat:@"%li", y]];
    
    
    //COLOR log
    transf = [NSString stringWithFormat:@"df[%li]", c];
    if(cMode == 1)transf = [NSString stringWithFormat:@"log(%@)", transf.copy];
    if(cMode == 2)transf = [NSString stringWithFormat:@"asinh(%@/5)", transf.copy];
    //COLOR
    if(c > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_COLOR_GGPLOT withString:
                        [plotType  isEqualToString:@"geom_tile"]?
                        @"":[NSString stringWithFormat:@", color = %@", transf.copy]];
    else
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_COLOR_GGPLOT withString:@""];
    
    templateFile = [templateFile stringByReplacingOccurrencesOfString:C_CHANNEL withString:[NSString stringWithFormat:@"%li", c]];
    
    //SHAPE
    if(s > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_SHAPE_GGPLOT withString:
                        [NSString stringWithFormat:@", shape = as.factor(df[[%li]])", s]];
    else
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_SHAPE_GGPLOT withString:@""];
    
    //FACETS
    if(f1 > 0 && f2 > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_FACET_GGPLOT withString:
                        [NSString stringWithFormat:@"facet_grid(%@~%@)+",
                         f1 > 0?[NSString stringWithFormat:@"as.factor(df[[%li]])", f1]:@".",
                         f2 > 0?[NSString stringWithFormat:@"as.factor(df[[%li]])", f2]:@"."]];
    else if(f1 > 0 || f2 > 0)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_FACET_GGPLOT withString:
                        [NSString stringWithFormat:@"facet_wrap(~%@)+",
                         [NSString stringWithFormat:@"as.factor(df[[%li]])", f1 > 0?f1:f2]]];
    else
        templateFile = [templateFile stringByReplacingOccurrencesOfString:VAR_FACET_GGPLOT withString:@""];
    
    templateFile = [templateFile stringByReplacingOccurrencesOfString:SIZE_GPOINT withString:
                    [NSString stringWithFormat:@"%.2f", size]];
    templateFile = [templateFile stringByReplacingOccurrencesOfString:ALPHA_GPOINT withString:
                    [NSString stringWithFormat:@"%.2f", alpha]];
    
    
    if(inOrderChannels.count > 2)
        templateFile = [templateFile stringByReplacingOccurrencesOfString:LEGEND_TITLE withString:@"scale_fill_discrete(name=\"TEST\")+"];
    else templateFile = [templateFile stringByReplacingOccurrencesOfString:LEGEND_TITLE withString:@""];
    
    return templateFile;
    
}

-(NSImage *)plotType:(NSString *)plotType WithComputations:(NSArray <IMCComputationOnMask *>*)computations channels:(NSArray *)inOrderChannels xMode:(NSInteger)xMode yMode:(NSInteger)yMode cMode:(NSInteger)cMode channelX:(NSInteger)x channelY:(NSInteger)y channelC:(NSInteger)c channelS:(NSInteger)s channelF1:(NSInteger)f1 channelF2:(NSInteger)f2 size:(float)size alpha:(float)alpha colorPoints:(NSColor *)colorPoints colorScale:(NSInteger)colorScale{
        
    [self prepareDataMultiImage:computations channels:inOrderChannels];
    
    NSString *rScript = [self rScriptWithPlotType:plotType WithComputations:computations channels:inOrderChannels xMode:xMode yMode:yMode cMode:cMode channelX:x channelY:y channelC:c channelS:s channelF1:f1 channelF2:f2 size:size alpha:alpha colorPoints:colorPoints colorScale:colorScale];
    
    return [self runWithScript:rScript];
}

-(NSImage *)runWithScript:(NSString *)rScript{
    
    NSError *error;
    [rScript writeToFile:[self getTempScriptPath] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
        [self logError:error];
    
    NSString *pathInternalR = [[NSUserDefaults standardUserDefaults]valueForKey:PREF_LOCATION_DRIVE_R];//[[NSBundle mainBundle]pathForResource:@"R" ofType:@"framework"];
    pathInternalR = pathInternalR ? pathInternalR : TYPICAL_R_LOCATION;
    pathInternalR = [pathInternalR stringByAppendingPathComponent:PATH_R_INTERNAL_EXTENSION];
    
    NSLog(@"Path internal R %@", pathInternalR);
    NSImage *im = nil;
    if([[NSFileManager defaultManager]fileExistsAtPath:pathInternalR]){
        [[NSTask launchedTaskWithLaunchPath:pathInternalR arguments:@[[self getTempScriptPath]]]waitUntilExit];
        im = [[NSImage alloc]initWithContentsOfFile:[self getTempPathResultPath]];
        if([[NSFileManager defaultManager]fileExistsAtPath:[self getTempPathResultPath]])
            [[NSFileManager defaultManager]removeItemAtPath:[self getTempPathResultPath] error:NULL];
    }else{
        [General runAlertModalWithMessage:[@"You need to ensure that the R framework is available. Install R if necessary and go to Preferences to specify the location of the R.framework (usually installed at " stringByAppendingString:[TYPICAL_R_LOCATION stringByAppendingString:@")"]]];
    }
    return im;
}

-(void)main{
    @autoreleasepool {
        //[self exampleR];
    }
}

@end
