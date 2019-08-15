//
//  IMC_MCDLoader.m
//  3DIMC
//
//  Created by Raul Catena on 1/20/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMC_MCDLoader.h"
#import "XMLDictionary.h"
#import "IMCPanoramaWrapper.h"
#import "IMCImageStack.h"

@implementation IMC_MCDLoader


+(void)selectedPanorama:(NSDictionary *)panDict andData:(NSData *)data panWrapper:(IMCPanoramaWrapper *)panWrapper roiOrDict:(NSDictionary *)acq{
    
    //Before Fludigim changed this
    //NSInteger beggining = [[panDict valueForKey:@"ImageStartOffset"]integerValue];
    //NSInteger end = [[panDict valueForKey:@"ImageEndOffset"]integerValue];
    
    NSInteger beggining = [[acq valueForKey:@"BeforeAblationImageStartOffset"]integerValue];
    NSInteger end = [[acq valueForKey:@"BeforeAblationImageEndOffset"]integerValue];
    
    NSInteger begginingAfter = [[acq valueForKey:@"AfterAblationImageStartOffset"]integerValue];
    NSInteger endAfter = [[acq valueForKey:@"AfterAblationImageEndOffset"]integerValue];
    
    //CGFloat prop = (CGFloat)width/height;//a = w * h // a = w * w/prop //w^2 = a * prop // w = sqrt(a * prop)
    beggining += 161;
    begginingAfter += 161;
    
    if(end > beggining && end < data.length){
        panWrapper.panoramaImage = [[NSImage alloc]initWithData:[data subdataWithRange:NSMakeRange(beggining, end - beggining)]];
        panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_COEF] = [panDict valueForKey:@"PixelScaleCoef"];
        if(!panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_W] || [panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_W]integerValue] == 0)
            panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_W] = [NSNumber numberWithFloat:panWrapper.panoramaImage.size.width];
        if(!panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_H] || [panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_H]integerValue] == 0)
            panWrapper.jsonDictionary[JSON_DICT_CONT_PANORAMA_H] = [NSNumber numberWithFloat:panWrapper.panoramaImage.size.height];
    }
    if(endAfter > begginingAfter && endAfter < data.length)
        panWrapper.afterPanoramaImage = [[NSImage alloc]initWithData:[data subdataWithRange:NSMakeRange(begginingAfter, endAfter - begginingAfter)]];    
}

+(BOOL)loadMCD:(NSData *)data toIMCFileWrapper:(IMCFileWrapper *)wrapper{
    NSString *xml = [IMC_MCDLoader parseDataFromMCDFile:data];
    if (xml) {
        //theImageModel.mcdMetadata = [self dictionaryFromXml:xml];
        NSDictionary *xmlDict = [IMC_MCDLoader dictionaryFromXml:xml];
        NSArray *panoramas = [IMC_MCDLoader panoramasFormXml:xmlDict];
        
        NSMutableArray *panArray = wrapper.containers;
        if(!panArray)
            panArray = @[].mutableCopy;
        
        
        for (NSDictionary *pan in panoramas) {
            
            NSMutableDictionary *panDict;
            
            for (NSMutableDictionary *dict in panArray){
                if([dict[JSON_DICT_CONT_PANORAMA_NAME]isEqualToString:pan[@"Description"]])
                    panDict = dict;
            }
            
            if(!panDict){
                panDict = @{JSON_DICT_CONT_PANORAMA_NAME:pan[@"Description"], JSON_DICT_CONT_IS_PANORAMA:[NSNumber numberWithBool:YES],JSON_DICT_CONT_PANORAMA_W:pan[@"PixelWidth"], JSON_DICT_CONT_PANORAMA_H:pan[@"PixelHeight"]}.mutableCopy;
                [panArray addObject:panDict];
            }
            
            IMCPanoramaWrapper *panWrapper;
            for (IMCPanoramaWrapper *panW in wrapper.children)
                if(panW.jsonDictionary == panDict)
                    panWrapper = panW;
            if(!panWrapper){
                panWrapper = [[IMCPanoramaWrapper alloc]init];
                panWrapper.jsonDictionary = panDict;
            }
            
            NSArray *rois = [IMC_MCDLoader roisFormXml:xmlDict panoramaId:[pan[@"ID"]intValue]];
            for (NSDictionary *roi in rois) {
                NSMutableDictionary *imageDict;
                for (NSMutableDictionary *dict in panDict[JSON_DICT_CONT_PANORAMA_IMAGES]){
                    
                    if([dict[JSON_DICT_IMAGE_ROI_INDEX]intValue] == [roi[@"ID"]intValue])
                        imageDict = [dict respondsToSelector:@selector(setObject:forKey:)]?dict:dict.mutableCopy;
                }
                NSArray *acqs = [IMC_MCDLoader acquisitionsForRoiId:[roi[@"ID"]intValue] dict:xmlDict];
                if(acqs.count > 1){
                    [General runAlertModalWithMessage:@"Error in MCD file"];
                    return NO;
                }
                if(!imageDict)
                    imageDict = @{JSON_DICT_IMAGE_ROI_INDEX:[NSNumber numberWithInt:[roi[@"ID"]intValue]],
                                            JSON_DICT_IMAGE_NAME: acqs[0][@"Description"],
                                            JSON_DICT_IMAGE_ALLDATA: roi.copy}.mutableCopy;
                
                
                CGRect rect = [IMC_MCDLoader rectFromArrayOfROIPoints:roi[@"points"]];
                imageDict[JSON_DICT_IMAGE_RECT_IN_PAN] = NSStringFromRect(rect);
                
                IMCImageStack *stk;
                for (IMCImageStack *stck in panWrapper.children){
                    if(stck.jsonDictionary == imageDict){
                        stk = stck;
                    }
                }
                
                if(!stk){
                    stk  = [[IMCImageStack alloc]init];
                    stk.jsonDictionary = imageDict;
                }
                
                BOOL success = [self loadFromData:data intoImageStack:stk withAcqDict:acqs.firstObject andXMLDict:xmlDict];
                if(!success)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [General runAlertModalWithMessage:
                         [NSString stringWithFormat:@"Error loading an acquisition: %@", imageDict[JSON_DICT_IMAGE_NAME]]];
                    });
                else{
                    if(!panWrapper.parent)
                        panWrapper.parent = wrapper;
                    stk.parent = panWrapper;
                    if(![[wrapper containers]containsObject:panDict]){
                        [[wrapper containers] addObject:panDict];
                    }
                    
                    if(![[panWrapper images]containsObject:imageDict]){
                        [[panWrapper images]addObject:imageDict];
                    }
                    if(roi == rois.firstObject)
                        [IMC_MCDLoader selectedPanorama:pan andData:data panWrapper:panWrapper roiOrDict:acqs[0]];
                }
            }
        }
        return YES;
    }
    return NO;
}

+(BOOL)loadFromData:(NSData *)data intoImageStack:(IMCImageStack *)stack withAcqDict:(NSDictionary *)dict andXMLDict:(NSDictionary *)xmlDict{
    
    NSInteger beggining = [dict[@"DataStartOffset"]integerValue];
    NSInteger end = [dict[@"DataEndOffset"]integerValue];

    if(beggining > end){
        dispatch_async(dispatch_get_main_queue(), ^{
            [General runAlertModalWithMessage:@"This image was not acquired\nThe ROI was setup but the image was not acquired"];
        });
        return NO;
    }

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:100];
    NSArray *unsortedArray = xmlDict[@"AcquisitionChannel"];

    
    NSArray *sortedArray = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(NSDictionary * a, NSDictionary * b) {
        return [a [@"OrderNumber"]integerValue] > [b [@"OrderNumber"]integerValue];
    }];
    
    for (NSDictionary *chan in sortedArray) {
        NSString *chanName = chan[@"ChannelLabel"];
        if(!chanName)chanName = chan[@"ChannelName"];
        if([chan[@"AcquisitionID"]integerValue] != [dict[@"ID"]intValue])continue;
        if(chanName)
            [array addObject:chanName];
        else [array addObject:@"Unknown"];
    }
    if(!stack.channels || stack.channels.count != array.count)
        stack.channels = array;
    if(!stack.origChannels || stack.origChannels.count != array.count)
        stack.origChannels = stack.channels.mutableCopy;
    
    stack.width = [dict[@"MaxX"]integerValue];
    stack.height = [dict[@"MaxY"]integerValue];
    
    NSInteger channelNumber = stack.channels.count;

    [stack clearBuffers];
    [stack allocateBufferWithPixels:stack.numberOfPixels];

    
//    float subBytes;
//    size_t size = sizeof(float);
//    NSInteger clockChannels = 0;
//    NSInteger clockPixs = 0;
//    for (NSUInteger i = beggining; i < end; i += size) {
//
//        if(clockChannels == channelNumber){
//            clockChannels = 0;
//            clockPixs++;
//        }
//
//        [data getBytes:&subBytes range:NSMakeRange(i, size)];
//
//        stack.stackData[clockChannels][clockPixs] = subBytes;
//        clockChannels++;
//    }
    
    
    
    //Faster load of MCD
    float subBytes[channelNumber];
    size_t size = sizeof(float);
    NSInteger clockPixs = 0;
    NSInteger stepChannels = size * channelNumber;
    float ** destination = stack.stackData;

    if(destination){
        for (NSUInteger i = beggining; i < end; i += stepChannels) {
            [data getBytes:subBytes range:NSMakeRange(i, stepChannels)];
            for(NSInteger j = 0; j < channelNumber; ++j)
                destination[j][clockPixs] = subBytes[j];
            clockPixs++;
        }
    }

    
    // Yet Faster load of MCD
//    size_t size = end - beggining;
//    NSInteger clockPixs = 0;
//    float ** destination = stack.stackData;
//
//    if(destination){
//        NSData *subData = [data subdataWithRange:NSMakeRange(beggining, size)];
//        size /= sizeof(float);
//        float * subBytes = (float *)subData.bytes;
//        for (NSUInteger i = 0; i < size; i += channelNumber) {
//            for(NSInteger j = 0; j < channelNumber; ++j)
//                destination[j][clockPixs] = subBytes[i + j];
//            clockPixs++;
//        }
//    }
    
//    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
//        NSLog(@"You get the chunk in range: %@", NSStringFromRange(byteRange));
//    }];
    
    return YES;
}

+(CGRect)rectFromArrayOfROIPoints:(NSArray *)array{
    if (array.count != 4)return CGRectZero;
    CGRect rect;
    rect.origin.x = [array[0][@"PanoramaPixelXPos"]floatValue];
    rect.origin.y = [array[0][@"PanoramaPixelYPos"]floatValue];
    rect.size.width = [array[1][@"PanoramaPixelXPos"]floatValue] - [array[0][@"PanoramaPixelXPos"]floatValue];
    rect.size.height = [array[2][@"PanoramaPixelXPos"]floatValue] - [array[0][@"PanoramaPixelXPos"]floatValue];
    return rect;
}

+(NSString *)parseDataFromMCDFile:(NSData *)data{
    NSArray *search = @[@"<", @"M", @"C", @"D", @"S", @"c", @"h"];
    NSInteger searchCount = search.count;
    NSData *kData = [[search lastObject] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *pData;
    
    NSRange whereIsGreater;
    
    NSInteger limit = data.length;
    
    
    int counter = 0;
    do {
        limit = [data rangeOfData:kData options:NSDataSearchBackwards range:NSMakeRange(0, limit)].location;
        
        if(limit > data.length)break;
        //printf("_%lu", limit);
        counter = 0;
        for (int i = 0; i < searchCount - 1; i++) {
            pData = [[search objectAtIndex:searchCount - i - 1]dataUsingEncoding:NSUTF8StringEncoding];
            whereIsGreater = [data rangeOfData:pData options:NSDataSearchBackwards range:NSMakeRange(limit - searchCount * 6, searchCount * 4)];
            if(whereIsGreater.length > 0){
                counter++;
            }
        }
    } while (counter < search.count - 1);
    
    printf("counter %i seach count %lu\n", counter, search.count);
    if (counter > searchCount - 2) {
        NSMutableData *mut = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(whereIsGreater.location - 2, data.length - whereIsGreater.location)]];
        NSMutableString *xml = @"".mutableCopy;
        for (int i = 0; i < mut.length; i+=1) {
            unsigned char bytes;
            [mut getBytes:&bytes range:NSMakeRange(i, 1)];
            //if(bytes == 00)continue;
            
            NSString *s = [NSString stringWithCString:(void *)&bytes encoding:NSASCIIStringEncoding];
            //NSLog(@"Para %@ %c de %i", s, bytes, bytes);
            if(s){
                if(s.length == 1)[xml appendString:s];
                else if(s.length > 1)[xml appendString:[s substringToIndex:1]];
            }
            //printf("%i ", bytes);
            //printf("%c ", bytes);
        }
        //NSLog(@"METADATA %@", xml);
        return xml;
    }
    return nil;
}

+(NSDictionary *)dictionaryFromXml:(NSString *)xml{
    NSDictionary *parsed = [NSDictionary dictionaryWithXMLString:xml];
    return parsed;
}

+(NSArray *)panoramasFormXml:(NSDictionary *)xmlParsed{
    id pans = [xmlParsed valueForKey:@"Panorama"];
    if([pans respondsToSelector:@selector(allKeys)])return @[pans];
    return pans;
}

+(NSArray *)acquisitionsFormXml:(NSDictionary *)xmlParsed{
    id pans = [xmlParsed valueForKey:@"Acquisition"];
    if([pans respondsToSelector:@selector(allKeys)])return @[pans];
    return pans;
}

+(NSArray *)acquisitionsForRoiId:(int)roiId dict:(NSDictionary *)xmlParsed{
    NSMutableArray *arr = @[].mutableCopy;
    NSArray * acquisitions = [IMC_MCDLoader acquisitionsFormXml:xmlParsed];
    for (NSDictionary *acq  in acquisitions) {
        if([[acq valueForKey:@"AcquisitionROIID"]intValue] == roiId)
           [arr addObject:acq];
    }
    return [NSArray arrayWithArray:arr];
}

+(NSArray *)roisFormXml:(NSDictionary *)xmlParsed panoramaId:(int)idPan{
    id acqRois = [xmlParsed valueForKey:@"AcquisitionROI"];
    if([acqRois respondsToSelector:@selector(allKeys)])acqRois = @[acqRois];
    
    NSMutableArray *roisPan = [NSMutableArray arrayWithCapacity:[(NSArray *)acqRois count]];
    for (NSDictionary *roi in acqRois) {
        if([[roi valueForKey:@"PanoramaID"]intValue] == idPan)
            [roisPan addObject:roi.mutableCopy];
    }
    
    id pans = [xmlParsed valueForKey:@"ROIPoint"];
    if([pans respondsToSelector:@selector(allKeys)])pans = @[pans];
    for (NSDictionary *roiPoint in pans) {
        for (NSMutableDictionary *roi in roisPan) {
            if([[roiPoint valueForKey:@"AcquisitionROIID"]isEqualToString:[roi valueForKey:@"ID"]]){
                if(![roi valueForKey:@"points"])[roi setValue:@[].mutableCopy forKey:@"points"];
                NSMutableArray *arr = [roi valueForKey:@"points"];
                [arr addObject:roiPoint];
            }
        }
    }
    
    return roisPan;
}

@end
