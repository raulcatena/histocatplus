//
//  IMCWaterShedSegmenter.m
//  3DIMC
//
//  Created by Raul Catena on 10/23/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCWaterShedSegmenter.h"
#import "IMCImageStack.h"
#import "IMCPixelClassification.h"
#import "IMCMasks.h"
//#import "NSImage+OpenCV.h"
//#import "IMCImageGenerator.h"

@interface IMCWaterShedSegmenter(){
    int * maskIds;
}
@end

@implementation IMCWaterShedSegmenter

+(void)wizard2DWatershedIndexes:(NSArray *)inOrderIndexes scopeImage:(IMCImageStack *)inScopeImage scopeImages:(NSArray<IMCImageStack *>*)inScopeImages{
    
    if(inOrderIndexes.count == 0 || !inScopeImage || inScopeImages.count == 0){
        [General runAlertModalWithMessage:@"You must select at least one image and one channel to proceed"];
        return;
    }
    
    NSString *input;
    
    NSMutableString *chanNames = @"".mutableCopy;
    for (NSNumber *chan in inOrderIndexes)
        [chanNames appendFormat:@"%@, ", inScopeImage.channels[chan.integerValue]];
    
    [chanNames deleteCharactersInRange:NSMakeRange(chanNames.length - 1, 1)];
    
    NSInteger go = [General runAlertModalWithMessage:[NSString stringWithFormat:
                                                      @"Do you want to segment the selected %li image%@ using the selected channels %@ ?", inScopeImages.count, inScopeImages.count == 1 ? @"":@"s", chanNames]];
    if(go == NSAlertSecondButtonReturn)
        return;
    
    int kernel = 0;
    do{
        input = [IMCUtils input:@"Minimum number of voxels per kernel (e.g.: 12-10000)" defaultValue:@"12"];
        if(!input)
            return;
    }while (input.integerValue <= 0);
    kernel = input.intValue;
    
    float gradient = 0;
    do{
        input = [IMCUtils input:@"Step for watershed gradient (e.g.: 0.005-0.1)" defaultValue:@"0.02"];
        if(!input)
            return;
    }while (input.floatValue <= 0);
    gradient = input.floatValue;
    
    float threshold = 0;
    do{
        input = [IMCUtils input:@"Percentage threshold (e.g.: 0.1 - 0.8)" defaultValue:@"0.2"];
        if(!input)
            return;
    }while (input.floatValue <= 0);
    threshold = input.floatValue;
    
    NSInteger channel = [inOrderIndexes[0]integerValue];
    
    NSInteger sChannel = 0;
    do{
        NSArray *channs = [@[@"None"] arrayByAddingObjectsFromArray:inScopeImage.channels.copy];
        sChannel = [IMCUtils inputOptions:channs prompt:@"Do you want to use a channel to frame the nuclear signal?"];
    }while (sChannel < 0 || sChannel == channel + 1);
    
    int expansion = 0;
    do{
        input = [IMCUtils input:@"Do you want to add expansion layer? (e.g.: 0-100)" defaultValue:@"1"];
        if(!input)
            return;
    }while (input.integerValue < 0);
    expansion = input.intValue;
    
    NSDictionary *dict1 = [inScopeImage.channelSettings[channel]copy];
    NSDictionary *dict2 = nil;
    if(sChannel > 0)
        dict2 = [inScopeImage.channelSettings[sChannel]copy];
    
    input = [IMCUtils input:@"Name this segmentation task" defaultValue:@"Segmentation_"];
    
    dispatch_queue_t aQ = dispatch_queue_create([IMCUtils randomStringOfLength:5].UTF8String, NULL);
    dispatch_async(aQ, ^{
        for (IMCImageStack *stack in inScopeImages.copy)
            [IMCWaterShedSegmenter extractMaskFromRender:stack channels:inOrderIndexes dictChannel:dict1 framingChannel:sChannel - 1 dictSChannel:dict2 threshold:threshold gradient:gradient minKernel:kernel expansion:expansion name:input];
    });
}

+(int)touchesId:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength width:(NSInteger)width mask:(int *)maskIds{
    
    NSInteger test = 0;
    NSMutableDictionary *dic = @{}.mutableCopy;
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            test = testIndex + i * width + j;
            if(test > 0 && test < fullMaskLength)
                if(maskIds[test] > 0){
                    NSNumber *keyNum = @(maskIds[test]);
                    dic[keyNum] = dic[keyNum]?@([dic[keyNum]integerValue]+1):@(1);
                }
        }
    }
    if(dic.allKeys.count == 1)
        return [dic.allKeys.firstObject intValue];
    if(dic.allKeys.count > 1){
        return [[NSSet setWithArray:dic.allKeys].anyObject intValue];//0;
    }
    
    return -1;
}

+(BOOL)hasZeroNeighbor:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength width:(NSInteger)width mask:(int *)maskIds{
    
    NSInteger test = 0;
    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            test = testIndex + i * width + j;
            if(test > 0 && test < fullMaskLength)
                if(test > 0 && test < fullMaskLength)
                    if(maskIds[test] == 0)
                        return YES;
            if(test < 0 || test >= fullMaskLength)
                return YES;
        }
    }
    return NO;
}
+(void)fillHoles:(int)radius fullMaskLength:(NSInteger)fullMaskLength width:(NSInteger)width mask:(int *)maskIds{
    NSInteger zeroes = 0, cases = 0, equals = 0;
    for (NSInteger pix = 0; pix < fullMaskLength; pix++) {
        if(maskIds[pix] == 0){
            zeroes++;
            
            NSMutableArray *arr = @[].mutableCopy;
            
            for (int i = 0; i < 4; i++) {//Directions
                for (int d = 0; d < radius; d++) {
                    NSInteger test = pix;
                    switch (i) {
                        case 0:
                            test -= d * width;
                            break;
                        case 1:
                            test += d * width;
                            break;
                        case 2:
                            test += d;
                            break;
                        case 3:
                            test -= d;
                            break;
                        default:
                            break;
                    }
                    if(test >= 0 && test < fullMaskLength){
                        if(maskIds[test] > 0){
                            [arr addObject:@(maskIds[test])];
                            break;
                        }
                    }else{
                        break;
                    }
                }
            }
            if(arr.count == 4){
                cases++;
                int count = 1;
                int theId = [arr.firstObject intValue];
                for (int r = 1; r < 4; r++)
                    if([arr[r]intValue] == theId)
                        count++;
                if(count == 4 )
                    equals++;
                    maskIds[pix] = theId;
            }
        }
    }
    printf("case %li of tested %li %li", cases, zeroes, equals);
}

+(void)assignId:(int)cellId toIndex:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength width:(NSInteger)width mask:(int *)maskIds{
    maskIds[testIndex] = cellId;
    
    NSMutableArray *arr = @[].mutableCopy;
    NSNumber *inScopeNumber = @(testIndex);
    do{
        NSInteger val = inScopeNumber.integerValue;
        NSInteger candidates[4] = {val - width,
            val + width,
            val - 1,
            val + 1,
        };
        for (int m = 0; m < 4;  m++){
            if(candidates[m] > 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == -1){
                    maskIds[candidates[m]] = cellId;
                    [arr addObject:@(candidates[m])];
                }
        }
        
        inScopeNumber = [arr lastObject];
        [arr removeLastObject];
    }
    while (inScopeNumber);
}

+(int)checkCandidates:(NSInteger)testIndex fullMaskLength:(NSInteger)fullMaskLength width:(NSInteger)width mask:(int *)maskIds{
    int candidatesCount = 0;
    
    NSMutableArray *arr = @[].mutableCopy;
    NSMutableArray *visited = @[].mutableCopy;
    
    NSNumber *inScopeNumber = @(testIndex);
    do{
        NSInteger val = inScopeNumber.integerValue;
        NSInteger candidates[4] = {
            val - width,
            val + width,
            val - 1,
            val + 1,
        };
        for (int m = 0; m < 4;  m++){
            if(candidates[m] >= 0 && candidates[m] < fullMaskLength)
                if(maskIds[candidates[m]] == -1){
                    maskIds[candidates[m]] = -2;
                    //if(![arr containsObject:@(candidates[m])])
                    [arr addObject:@(candidates[m])];
                }
            
        }
        candidatesCount++;
        [visited addObject:inScopeNumber];
        inScopeNumber = [arr lastObject];
        [arr removeLastObject];
    }
    while (inScopeNumber);
    
    for (NSNumber *num in visited)
        maskIds[num.integerValue] = -1;
    
    return candidatesCount;
}

+(void)resetNegs:(NSInteger)allLength mask:(int *)maskIds{
    for (NSInteger i = 0; i < allLength; i++)
        if(maskIds[i] < 0)
            maskIds[i] = 0;
}

int gaussianMatrix [9][3] = {
    {-1, -1, 1},
    {0, -1, 2},
    {1, -1, 1},
    {-1, 0, 2},
    {0, 0, 4},
    {1, 0, 2},
    {-1, 1, 1},
    {0, 1, 2},
    {1, 1, 1}
};

+(void)gaussianFilter2D_l3:(NSInteger)width allLength:(NSInteger)planePixels buff:(UInt8 *)buff receiver:(UInt8 *)newBuff{
    
    UInt8 * a = (UInt8 *)calloc(planePixels, sizeof(UInt8));
    for (NSInteger pix = 0; pix < planePixels; pix++) {
        float sum = 0;
        NSInteger blurCounter = 0;
        for (int i = 0; i < 9; i++) {
            NSInteger index = pix + gaussianMatrix[i][0] + width * gaussianMatrix[i][1];
            //TODO jumper
            if( index < 0 || index >= planePixels)
                continue;
            
            sum += buff[index] *  gaussianMatrix[i][2];
            blurCounter += gaussianMatrix[i][2];
            
        }
        a[pix] = MIN(255, (UInt8)(sum/blurCounter));
    }
    for (NSInteger pix = 0; pix < planePixels; pix++) {
        newBuff[pix] = a[pix];
    }
    free(a);
}

+(void)extractMaskFromRender:(IMCImageStack *)stack channels:(NSArray *)inOrderIndexes dictChannel:(NSDictionary *)dictChannel framingChannel:(NSInteger)schannel dictSChannel:(NSDictionary *)dictSChannel threshold:(float)threshold gradient:(float)gradient minKernel:(int)minKernel expansion:(int)expansion name:(NSString *)name{
    
    NSUInteger width = stack.width;
    NSUInteger height = stack.height;
    
    NSInteger allLength = width * height;
    
    int * maskIds = (int *)calloc(allLength, sizeof(int));
    
    [stack openIfNecessaryAndPerformBlock:^{
        UInt8 ** chanImage = [stack preparePassBuffers:inOrderIndexes];
        UInt8 * chanImageS = NULL;
        if(schannel >= 0)
            chanImageS= [stack preparePassBuffers:@[@(schannel)]][0];
        
        if(chanImage){
            UInt8 ** copies = (UInt8 **)calloc(inOrderIndexes.count, sizeof(UInt8 *));
            for (int a = 0; a < inOrderIndexes.count; a++) {
                copies[a] = (UInt8 *)calloc(allLength, sizeof(UInt8));
                [self gaussianFilter2D_l3:width allLength:allLength buff:chanImage[a] receiver:copies[a]];
            }
            
//            for (NSNumber * idx in inOrderIndexes) {
//                NSInteger index = [inOrderIndexes indexOfObject:idx];
//                NSImage *im = [IMCImageGenerator imageForImageStacks:@[stack].mutableCopy indexes:@[@(index)] withColoringType:0 customColors:nil minNumberOfColors:0 width:stack.width height:stack.height withTransforms:NO blend:kCGBlendModeScreen andMasks:nil andComputations:nil maskOption:MASK_FULL maskType:MASK_ALL_CELL maskSingleColor:nil isAlignmentPair:NO brightField:NO];
//                UInt8 * data = (UInt8 *)[im obtainCentroidpixelsData];
//                copies[index] = (UInt8 *)malloc(allLength * sizeof(UInt8));
//                for (NSInteger l = 0; l < allLength; l++)
//                    copies[index][l] = data[l];
//            }
            UInt8 * copyS = (UInt8 *)calloc(allLength, sizeof(UInt8));
            
            if(chanImageS)
                [self gaussianFilter2D_l3:width allLength:allLength buff:chanImageS receiver:copyS];
            
            int cellId = 1;
            for (float analyze = 1.0f; analyze > threshold; analyze -= gradient) {
                //Add Values
                float analyzeAdded = analyze * 255;
                NSLog(@"%f step", analyzeAdded);
                
                for (NSInteger j = 0; j < allLength; j++){
                    if(maskIds[j] == -1){
                        int neigh = [IMCWaterShedSegmenter touchesId:j fullMaskLength:allLength width:width mask:maskIds];
                        if(neigh > 0)
                            maskIds[j] = neigh;
                    }
                    if(maskIds[j] == 0){
                        int val = 0;
                        for (int a = 0; a < inOrderIndexes.count; a++)
                            val += copies[a][j];
                        
                        if(schannel >= 0 && copyS)
                            val = MAX(0, val - copyS[j]);
                        val = MIN(255, val);
                        if(val >= analyzeAdded){
                            maskIds[j] = [IMCWaterShedSegmenter touchesId:j fullMaskLength:allLength width:width mask:maskIds];
                        }
                    }
                }
                for (NSInteger j = 0; j < allLength; j++){
                    if(maskIds[j] == -1){
                        int qual = [IMCWaterShedSegmenter checkCandidates:j fullMaskLength:allLength width:width mask:maskIds];
                        if(qual >= minKernel){//Promote all
                            [IMCWaterShedSegmenter assignId:cellId toIndex:j fullMaskLength:allLength width:width mask:maskIds];
                            cellId++;
                        }
                    }
                }
            }
            NSLog(@"Assigned %i", cellId);
            [self fillHoles:4 fullMaskLength:allLength width:width mask:maskIds];
            
            for (int a = 0; a < inOrderIndexes.count; a++)
                free(copies[a]);
            free(copies);
            free(copyS);
        }
    }];
    
    //Reset negative values
    [IMCWaterShedSegmenter resetNegs:allLength mask:maskIds];
    
    IMCPixelClassification *mask = [[IMCPixelClassification alloc]init];
    mask.parent = stack;
    mask.isLoaded = YES;
    mask.mask = maskIds;
    mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_CELL] = @YES;
    mask.itemName = [name stringByAppendingFormat:@"_%@", stack.itemName];;
    
    //Expand
    if(expansion > 0){
        mask.jsonDictionary[JSON_DICT_PIXEL_MASK_IS_DUAL] = @YES;
        [IMCWaterShedSegmenter expand:expansion length:allLength width:width mask:maskIds];
    }
    [mask saveFileWith32IntBuffer:maskIds length:allLength];
}

+(void)expand:(int)expansion length:(NSInteger)allLength width:(NSInteger)width mask:(int *)maskIds{

    NSInteger height = allLength/width;
    int * original = copyMask(maskIds, (int)width, (int)height);

    for (NSInteger i = 0; i < expansion; i++) {
        for (NSInteger j = 0; j < allLength; j++) {

            int val = maskIds[j];
            if(val > 0){
                NSInteger candidates[4] = {j - width,
                    j + width,
                    j - 1,
                    j + 1,
                };
                for (int m = 0; m < 4;  m++)
                    if(doesNotJumpLine(j, candidates[m], width, height, allLength, 4))
                        if(maskIds[candidates[m]] == 0)
                            maskIds[candidates[m]] = -val;
            }
        }
        for (NSInteger j = 0; j < allLength; j++)
            if(maskIds[j] < 0)
                maskIds[j] = -maskIds[j];
    }

    for (NSInteger j = 0; j < allLength; j++)
        if(original[j] > 0)
            maskIds[j] = -original[j];
}

@end
