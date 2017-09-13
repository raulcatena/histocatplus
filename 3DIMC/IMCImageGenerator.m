//
//  IMCImageGenerator.m
//  3DIMC
//
//  Created by Raul Catena on 1/21/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCImageGenerator.h"
#import "IMCImageStack.h"
#import "IMCTiledScrollView.h"
#import "NSString+MD5.h"
#import "IMCPixelClassification.h"
#import "IMCComputationOnMask.h"

@implementation IMCImageGenerator

#define radians(degrees) (degrees * 3.1415/180)

+(float)degressToRadians:(float)degrees{
    return degrees * M_PI / 180;
}
+(float)radiansToDegrees:(float)radians{
    return radians * 180 / M_PI;
}


#pragma mark Buffer Filters

void applyFilterToPixelData(UInt8 * pixelData, NSInteger width, NSInteger height, NSInteger mode, float factor, NSInteger layers, NSInteger channels){
    NSInteger total = width * height;
    NSInteger totalWithChannels = total * channels;
    for (int i = 0; i < totalWithChannels; i+=channels) {
        NSInteger sum = 0;
        NSInteger otherIndex = -1;
        for (NSInteger j = -layers; j<layers + 1; j++) {//Going up-down
            for (NSInteger k = -layers; k<layers + 1; k++) {//Going left-right
                otherIndex = i + channels * j * width - channels * k;
                if (otherIndex >=0 && otherIndex < totalWithChannels && otherIndex != i){
                    //for(NSInteger l = 0; l < 2; l++){
                    //    NSInteger idx = otherIndex + l;
                    //    if(idx >= 0 && idx < total)
                    sum += pixelData[otherIndex];// + l];
                    //}
                }
            }
        }
        int vals = pixelData[i] + pixelData[i+1] + pixelData[i+2];
        if (sum < vals*factor) {
            for(int j = 0; j < channels; j++)pixelData[i + j] = 0;
        }
    }
}

void applySmoothingFilterToPixelData(UInt8 * pixelData, NSInteger width, NSInteger height, NSInteger mode, NSInteger layers){
    
    NSInteger * temp = calloc(width * height * 3, sizeof(int));
    NSInteger totalComps = width * height * 3;
    
    for (int i = 0; i < totalComps; i++) {
        NSInteger sum = pixelData[i];
        NSInteger otherIndex = -1;
        for (NSInteger j = -layers; j<layers + 1; j++) {//Going up-down
            for (NSInteger k = -layers; k<layers + 1; k++) {//Going left-right
                otherIndex = i + 3 * j * width - 3 * k;
                if (otherIndex >=0 && otherIndex < totalComps && otherIndex != i){
                    sum += pixelData[otherIndex]/9;;
                }
            }
        }
        temp[i] = sum;
    }
    for (int i = 0; i< totalComps; i++) {
        pixelData[i] = MIN(255, temp[i]);
    }
    free(temp);
}

BOOL doesJumpLineTest(NSInteger index, NSInteger indexTest, NSInteger width, NSInteger height, NSInteger total, NSInteger expectedDistance){
    if(indexTest>=total || indexTest < 0)
        return YES;
    if(labs((indexTest+width)%width - (index+width)%width) > expectedDistance)
        return YES;
    return NO;
}

void threeDMeanBlur(float *** data, NSInteger width, NSInteger height, NSInteger stackCount, NSIndexSet * channels, NSInteger mode, bool *mask){
    
    if(data == NULL || mode == 0)
        return;
    
    NSInteger planePixels = width * height;
    
    [channels enumerateIndexesUsingBlock:^(NSUInteger chann, BOOL *stop){
        
        float* temp1Buffer[2];
        for (int i = 0; i < 2; i++) {
            temp1Buffer[i] = malloc(sizeof(float) * planePixels);
        }
        
        NSInteger blurCounter = 0;
        float sum = 0;
        NSInteger tempBufferUse = 0;
        
        for (NSInteger stack = 0; stack < stackCount; stack++) {
            //Probably never the case
            if(data[stack] == NULL)
                continue;
            
            float *prevLayer = stack > 0 ? data[stack - 1][chann] : NULL;
            float *layer = data[stack][chann];
            float *postLayer = stack < stackCount - 1 ? data[stack + 1][chann] : NULL;
            
            //Channel was not loaded. Break channel and go to next
            if(layer == NULL)
                continue;
            
            for (NSInteger pix = 0; pix < planePixels; pix++) {
                
                if(mask[pix] == false)
                    continue;
                
                blurCounter = 0;
                sum = 0;
                
                if(mode < 3){
                    for (NSInteger x = -1; x < 2; x++) {
                        for (NSInteger y = -1; y < 2; y++) {
                            NSInteger index = pix + x + width * y;
                            //if( doesJumpLineTest(pix, index, width, height, planePixels, 2))
                            if(index < 0 || index >= planePixels)
                                continue;
                            
                            if(prevLayer){
                                sum += prevLayer[index];
                                blurCounter++;
                            }
                            sum += layer[index];
                            blurCounter++;
                            if(postLayer){
                                sum += postLayer[index];
                                blurCounter++;
                            }
                        }
                    }
                    //Despecke filter
                    if(mode == 1)
                        temp1Buffer[tempBufferUse][pix] = sum - layer[pix] < layer[pix]? 0 : layer[pix];
                    //Mean filter
                    if(mode == 2)
                        temp1Buffer[tempBufferUse][pix] = sum/blurCounter;
                    
                }
                //Gaussian
                if(mode == 3){
                    
                    int cached [9][3] = {
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
                    
                    for (int i = 0; i < 9; i++) {
                        NSInteger index = pix + cached[i][0] + width * cached[i][1];
                        //TODO jumper
                        //if( doesJumpLineTest(pix, index, width, height, planePixels, 2))
                        if(index < 0 || index >= planePixels)
                            continue;
                        
                        if(prevLayer){
                            sum += (prevLayer[index] * cached[i][2]);
                            blurCounter += cached[i][2];
                        }
                        
                        sum += layer[index] *  cached[i][2] * 2;
                        blurCounter += cached[i][2] * 2;
                        
                        if(postLayer){
                            sum += postLayer[index] * cached[i][2];
                            blurCounter += cached[i][2];
                        }
                        
                    }
                    
                    //Gaussian filter
                    if(mode == 3)
                        temp1Buffer[tempBufferUse][pix] = sum/(blurCounter/2);
                    
                }
            }
            tempBufferUse = (NSInteger)!tempBufferUse;
            
            if(prevLayer)
                for (NSInteger pix = 0; pix < planePixels; pix++)
                    prevLayer[pix] = temp1Buffer[tempBufferUse][pix];
            
            if(postLayer == NULL){
                tempBufferUse = (NSInteger)!tempBufferUse;
                for (NSInteger pix = 0; pix < planePixels; pix++)
                    layer[pix] = temp1Buffer[tempBufferUse][pix];
            }
        }
        free(temp1Buffer[0]);
        free(temp1Buffer[1]);
    }];
}

#pragma mark canonical calling for a multicolor stack

+(NSImage *)imageForImageStacks:(NSMutableArray<IMCImageStack*>*)setStacks
                        indexes:(NSArray *)indexArray
               withColoringType:(NSInteger)coloringType
                   customColors:(NSArray *)customColors
              minNumberOfColors:(NSInteger)minAmountColors
                          width:(NSInteger)width
                         height:(NSInteger)height
                 withTransforms:(BOOL)applyTransforms
                          blend:(CGBlendMode)blend
                       andMasks:(NSArray<IMCPixelClassification *> *)masks
                andComputations:(NSArray<IMCComputationOnMask *>*)computations
                     maskOption:(NSInteger)maskOption
                       maskType:(MaskType)maskType
                maskSingleColor:(NSColor *)maskSingleColor
                isAlignmentPair:(BOOL)isAlignmentPair
                    brightField:(BOOL)brightField{
    
    NSArray *colors = [NSColor collectColors:indexArray.count withColoringType:coloringType minumAmountColors:minAmountColors];
    if(coloringType == 4)colors = customColors;
    if(colors)
        if(colors.count != indexArray.count)
            return nil;
    
    if(isAlignmentPair && (setStacks.count != 2 || indexArray.count > 2))
        return nil;
    
    NSMutableArray *arr = [setStacks mutableCopy];
    for (IMCPixelClassification *mask in masks)
        if(![arr containsObject:mask.imageStack])
            [arr addObject:mask.imageStack];
    
    NSMutableArray *refs = @[].mutableCopy;
    
    int i = 0;
    for (IMCImageStack *stck in setStacks) {

        if(!stck.isLoaded)continue;
        
        if(isAlignmentPair){
            NSArray *colors = @[[NSColor redColor], [NSColor cyanColor], [NSColor greenColor], [NSColor magentaColor]];
            if(coloringType == 1 || coloringType == 2)
                customColors = coloringType == 1 || coloringType == 2?
                    @[colors[(coloringType - 1) * 2 + i]]:
                    @[customColors[MIN(i, indexArray.count - 1)]];
        }
        CGImageRef ref = [IMCImageGenerator refForIMCStack:stck
                                                   indexes:indexArray
                                              coloringType:coloringType
                                              customColors:customColors
                                         minNumberOfColors:minAmountColors
                                                     width:width
                                                    height:height
                                            withTransforms:isAlignmentPair?YES:applyTransforms
                                                 blendMode:blend
                                               brightField:brightField];
        if(ref != NULL){
            [refs addObject:(__bridge id _Nonnull)(ref)];
            i++;
        }
    }
    
    for (IMCPixelClassification *mask in masks) {

        if(!mask.isLoaded)continue;
        
        CGImageRef ref = [IMCImageGenerator refMask:mask
                                       coloringType:coloringType width:width height:height withTransforms:applyTransforms blendMode:blend maskOption:maskOption maskType:maskType maskSingleColor:maskSingleColor];
        
        if(ref != NULL){
            [refs addObject:(__bridge id _Nonnull)(ref)];
            i++;
        }
    }
    for (IMCComputationOnMask *comp in computations) {
        NSLog(@"C");
        if(!comp.isLoaded)continue;
        
        CGImageRef ref = [IMCImageGenerator refForMaskComputation:comp indexes:indexArray coloringType:coloringType customColors:customColors minNumberOfColors:minAmountColors width:width height:height withTransforms:applyTransforms blendMode:blend maskOption:maskOption maskType:maskType maskSingleColor:maskSingleColor brightField:brightField];
        
        if(ref != NULL){
            [refs addObject:(__bridge id _Nonnull)(ref)];
            i++;
        }
    }

    return [IMCImageGenerator imageWithArrayOfCGImages:refs width:width height:height blendMode:blend];//Maybe General Transform
}

+(void)applyToTransform:(CGAffineTransform)transform onCanvas:(CGContextRef)canvas withStack:(IMCImageStack *)imageStack width:(NSInteger)width height:(NSInteger)height{
    NSDictionary *transformDict = imageStack.transform;
    float degrees = [transformDict[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue];
    float radians = [IMCImageGenerator degressToRadians:degrees];
    float offsetX = [transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue];
    float offsetY = [transformDict[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue];
    
    transform = CGAffineTransformTranslate(transform, offsetX, offsetY);
    transform = CGAffineTransformTranslate(transform, width/2, height/2);
    transform = CGAffineTransformRotate(transform, radians);
    transform = CGAffineTransformTranslate(transform, -width/2, -height/2);
    
    CGContextConcatCTM(canvas, transform);
}

+(CGImageRef)refForIMCStack:(IMCImageStack *)imageStack indexes:(NSArray *)indexArray coloringType:(NSInteger)coloringType customColors:(NSArray *)colors minNumberOfColors:(NSInteger)minAmountColors width:(NSInteger)width height:(NSInteger)height withTransforms:(BOOL)applyTransforms blendMode:(CGBlendMode)blend brightField:(BOOL)brightField{
    
    NSInteger bitsPerComponent = 8;
    NSInteger bytesPerPixel = 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerPixel * width, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGImageRef ref = NULL;
    if(canvas != NULL){
        CGContextSetBlendMode(canvas, blend);
        
        CGAffineTransform transform = CGAffineTransformIdentity;
        CGFloat paintWidth = imageStack.width;
        CGFloat paintHeight = imageStack.height;
        
        if(applyTransforms){
            [IMCImageGenerator applyToTransform:transform onCanvas:canvas withStack:imageStack width:width height:height];
            paintWidth *= [imageStack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
            paintHeight *= [imageStack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
        }
        
        UInt8 ** buffers = [imageStack preparePassBuffers:indexArray];
        
        CGRect framePaint = CGRectMake((width - paintWidth)/2 ,
                                       (height - paintHeight)/2,
                                       paintWidth,
                                       paintHeight);
        
        
        for (int i = 0; i < indexArray.count; i++) {
            
            UInt8 *buff = buffers[MIN(i, indexArray.count - 1)];
            NSColor * col;
            if(coloringType != 3)col = colors[MIN(i, indexArray.count - 1)];
            CGImageRef ref = [IMCImageGenerator imageFromCArrayOfValues:buff color:col width:imageStack.width height:imageStack.height startingHueScale:170 hueAmplitude:170 direction:NO ecuatorial:NO brightField:brightField];
            
            CGContextDrawImage(canvas, framePaint, ref);
            if(ref)
                CFRelease(ref);
        }
        ref = CGBitmapContextCreateImage (canvas);
        CFRelease(canvas);
    }
    CFRelease(colorSpace);
    return ref;
}

+(CGImageRef)refMask:(IMCPixelClassification *)mask coloringType:(NSInteger)coloringType width:(NSInteger)width height:(NSInteger)height withTransforms:(BOOL)applyTransforms blendMode:(CGBlendMode)blend maskOption:(NSInteger)maskOption maskType:(MaskType)maskType maskSingleColor:(NSColor *)maskSingleColor{
    
    NSInteger bitsPerComponent = 8;
    NSInteger bytesPerPixel = 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerPixel * width, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextSetBlendMode(canvas, blend);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    if(applyTransforms)
        [IMCImageGenerator applyToTransform:transform onCanvas:canvas withStack:mask.imageStack width:width height:height];
    
    CGRect framePaint = CGRectMake((width - mask.imageStack.width)/2 ,
                                   (height - mask.imageStack.height)/2,
                                   mask.imageStack.width,
                                   mask.imageStack.height);
    

    
    CGContextDrawImage(canvas, framePaint, [mask coloredMask:maskOption maskType:maskType singleColor:maskSingleColor]);
    
    
    CGImageRef ref = CGBitmapContextCreateImage (canvas);
    CFRelease(canvas);
    CFRelease(colorSpace);
    return ref;
}

+(CGImageRef)refForMaskComputation:(IMCComputationOnMask *)computation
                           indexes:(NSArray *)indexArray
                      coloringType:(NSInteger)coloringType
                      customColors:(NSArray *)colors
                 minNumberOfColors:(NSInteger)minAmountColors
                             width:(NSInteger)width
                            height:(NSInteger)height
                    withTransforms:(BOOL)applyTransforms
                         blendMode:(CGBlendMode)blend
                        maskOption:(NSInteger)maskOption
                          maskType:(MaskType)maskType
                   maskSingleColor:(NSColor *)maskSingleColor
                       brightField:(BOOL)brightField{
    
    NSInteger bitsPerComponent = 8;
    NSInteger bytesPerPixel = 4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerPixel * width, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGContextSetBlendMode(canvas, blend);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    CGFloat paintWidth = computation.mask.imageStack.width;
    CGFloat paintHeight = computation.mask.imageStack.height;
    
    if(applyTransforms){
        [IMCImageGenerator applyToTransform:transform onCanvas:canvas withStack:computation.mask.imageStack width:width height:height];
        paintWidth *= [computation.mask.imageStack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
        paintHeight *= [computation.mask.imageStack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
    }
    
    CGRect framePaint = CGRectMake((width - computation.mask.imageStack.width)/2 ,
                                   (height - computation.mask.imageStack.height)/2,
                                   paintWidth,
                                   paintHeight);
    
    for (int i = 0; i < indexArray.count; i++) {
        NSColor * col;
        if(coloringType != 3)
            col = colors[MIN(i, indexArray.count - 1)];
        CGImageRef aRef = [computation coloredMaskForChannel:[indexArray[i]integerValue] color:col maskOption:maskOption maskType:maskType maskSingleColor:maskSingleColor brightField:brightField];
        CGContextDrawImage(canvas, framePaint, aRef);
        CFRelease(aRef);
    }
    
    CGImageRef ref = CGBitmapContextCreateImage (canvas);
    CFRelease(canvas);
    CFRelease(colorSpace);
    return ref;
}

+(CGImageRef)imageRefWithArrayOfCGImages:(NSArray *)array width:(NSInteger)width height:(NSInteger)height blendMode:(CGBlendMode)blend{
    
    void * buffer = calloc(width * height * 4, sizeof(UInt8));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef canvas = CGBitmapContextCreate(buffer, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGImageRef ref = NULL;

    if(canvas != NULL){
        CGContextSetBlendMode(canvas, blend);//TODO. Pass Blend
        
        for (int i = 0; i < array.count; i++) {
            CGImageRef ref = (__bridge CGImageRef)array[i];
            CGRect framePaint = CGRectMake(0, 0, width, height);
            CGContextDrawImage(canvas, framePaint, ref);
            
        }
        for (int i = 0; i < array.count; i++) {
            CGImageRef ref = (__bridge CGImageRef)array[i];
            CFRelease(ref);
        }
        ref = CGBitmapContextCreateImage (canvas);
        CFRelease(canvas);
    }
    CGColorSpaceRelease(colorSpace);
    free(buffer);//RCF not sure I can leave this buffer alone
    return ref;
}

+(NSImage *)imageWithArrayOfCGImages:(NSArray *)array width:(NSInteger)width height:(NSInteger)height blendMode:(CGBlendMode)blend{
    
    CGImageRef ref = [IMCImageGenerator imageRefWithArrayOfCGImages:array width:width height:height blendMode:blend];
    NSImage *im = [[NSImage alloc]initWithCGImage:ref size:NSMakeSize(width, height)];
    if(ref != NULL)CFRelease(ref);
    return im;
}

+(CGImageRef)imageFromCArrayOfValues:(UInt8 *)array color:(NSColor *)color width:(NSInteger)width height:(NSInteger)height startingHueScale:(int)startHue hueAmplitude:(int)amplitude direction:(BOOL)positive ecuatorial:(BOOL)ecHueTraverse brightField:(BOOL)brightField{
    
    if (array == NULL)return NULL;
    
    CGFloat components[4];
    
    NSInteger sizePic = width * height;
    UInt8 * colorizedBuffer = (UInt8 *)calloc(sizePic, sizeof(UInt8) * 4);
    
    if(color){
        color = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];//In case it comes in other colorspace, like the white default
        [color getComponents:components];
        
        for(int ui = 0; ui < sizePic; ui++){
            UInt8 r = (UInt8) (components[0] * array[ui]);
            UInt8 g = (UInt8) (components[1] * array[ui]);
            UInt8 b = (UInt8) (components[2] * array[ui]);
            if (brightField) {
                float totalRation = (float)MAX(1, (r + g + b)/255.0f);
                colorizedBuffer[ui*4] = (UInt8)MAX(0, 255 - (g + b)/totalRation);
                colorizedBuffer[ui*4+1] = (UInt8)MAX(0, 255 - (r + b)/totalRation);
                colorizedBuffer[ui*4+2] = (UInt8)MAX(0, 255 - (r + g)/totalRation);
            }else{
                colorizedBuffer[ui*4] = r;
                colorizedBuffer[ui*4+1] = g;
                colorizedBuffer[ui*4+2] = b;
            }
            colorizedBuffer[ui*4+3] = 255;
        }
    }else{
        
        for(int ui = 0; ui < sizePic; ui++){
            
            //TODO refactor this
            HsvColor hsv;
            if(ecHueTraverse){
                float hue = startHue;
                if(array[ui] > 255.0f/2)hue -= 255.0f/2;
                if (startHue < 0)hue += 255.0f;
                hsv.h =  hue;
                hsv.s = 255;
                int v = abs(array[ui] - 255/2);
                hsv.v = MIN(255, v);
            }else{
                UInt8 calcVal;
                if(positive == YES)calcVal = (UInt8)(startHue + (float)array[ui]/255*amplitude);
                else calcVal = (UInt8)(startHue - (float)array[ui]/255*amplitude);
                hsv.h = calcVal;
                hsv.s = 255;
                hsv.v = 255;
            }
            
            if(array[ui] == 0)hsv.v = 0;
            RgbColor rgb = HsvToRgb(hsv);
            
            colorizedBuffer[ui*4] = rgb.r;
            colorizedBuffer[ui*4+1] = rgb.g;
            colorizedBuffer[ui*4+2] = rgb.b;
            colorizedBuffer[ui*4+3] = 255;
        }
    }
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CFDataRef rgbData = CFDataCreate(NULL, colorizedBuffer, width * height * 4);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    CGImageRef ref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    CFRelease(colorspace);
    CFRelease(rgbData);
    CFRelease(provider);
    free(colorizedBuffer);////TODO check if breaks
    return ref;
}

//This is the helper that together with IMCStack gives me the CGImageRef. This way I can call the original method for canonical now

+(CGImageRef)whiteImageFromCArrayOfValues:(UInt8 *)array width:(NSInteger)width height:(NSInteger)height{
    
    if (array == NULL)return NULL;
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CFDataRef data = CFDataCreate(NULL, array, width * height);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGImageRef ref = CGImageCreate(width, height, 8, 8, width, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    CFRelease(colorspace);
    CFRelease(data);
    CFRelease(provider);
    return ref;
}

//For registration
+(CGImageRef)whiteRotatedBufferForImage:(IMCImageStack *)stack atIndex:(NSInteger)index superCanvasW:(NSInteger)widthSuper superCanvasH:(NSInteger)heightSuper{
    
    UInt8 ** buffers = [stack preparePassBuffers:@[[NSNumber numberWithInteger:index]]];
    UInt8 *buff = buffers[0];
    
    CGImageRef ref = [IMCImageGenerator whiteImageFromCArrayOfValues:buff width:stack.width height:stack.height];
    
    UInt8 * subBuffer = calloc(widthSuper * heightSuper, sizeof(UInt8));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
    CGContextRef canvas = CGBitmapContextCreate(subBuffer, widthSuper, heightSuper, 8, widthSuper, colorSpace, kCGImageAlphaNone);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    float radians =  [IMCImageGenerator degressToRadians:[stack.transform[JSON_DICT_IMAGE_TRANSFORM_ROTATION]floatValue]];
    CGFloat w = stack.width * [stack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X]floatValue];
    CGFloat h = stack.height * [stack.transform[JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y]floatValue];
    
    CGRect framePaint = CGRectMake(0, 0, w, h);//Here will pass compression
    
    
    transform = CGAffineTransformTranslate(transform, (widthSuper - (float)stack.width)/2, (heightSuper -(float)stack.height)/2);
    transform = CGAffineTransformTranslate(transform,
                                           stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]?
                                           [stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_X]floatValue]:0,
                                           stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]?
                                           [stack.transform[JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y]floatValue]:0
                                           );
    
    transform = CGAffineTransformTranslate(transform, (float)stack.width/2, (float)stack.height/2);
    transform = CGAffineTransformRotate(transform, radians);
    transform = CGAffineTransformTranslate(transform, -(float)stack.width/2, -(float)stack.height/2);
    
    CGContextConcatCTM(canvas, transform);
    CGContextDrawImage(canvas, framePaint, ref);

    
    CGImageRef retRet = CGBitmapContextCreateImage(canvas);
    CFRelease(colorSpace);
    CFRelease(canvas);
    if(ref)
        CFRelease(ref);
    free(buffers);
    return retRet;
}

#pragma mark white raw CGImageRefs

+(UInt8 *)bufferForImageRef:(CGImageRef)imageRef{
//    CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(ref));
//    return (UInt8 *) CFDataGetBytePtr(rawData);
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    UInt8 *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return rawData;
}

+(void *)bufferImage:(IMCImageStack *)imageStack index:(NSInteger)index bitsPerPixel:(NSInteger)bitsPerPixel{
    if(bitsPerPixel != 8 && bitsPerPixel != 16)return NULL;
    
    float * data = imageStack.stackData[index];
    void *newBuffer = calloc(imageStack.numberOfPixels, bitsPerPixel/8);
    UInt8 *eightBitCasted = (UInt8 *)newBuffer;
    UInt16 *sixteenBitCasted = (UInt16 *)newBuffer;
        
    for (NSInteger i = 0, lenght = imageStack.numberOfPixels; i < lenght; i++) {
        if(bitsPerPixel == 8)eightBitCasted[i] = (UInt8)(data[i]/255.0f);//TODO check this. Maybe should not use max
        if(bitsPerPixel == 16)sixteenBitCasted[i] = (UInt16)data[i];
    }
    
    return newBuffer;
}

//+(void *)transformWhitebufferToRGB:(void *)buffer lenght:(NSInteger)length withBits:(NSInteger)bits finalBitsPerPixel:(NSInteger)bitsPerPixel{
//    if(bitsPerPixel != 24 && bitsPerPixel != 32)return NULL;
//    
//    UInt8 *newBuffer = (UInt8 *)calloc(length, bitsPerPixel/8);
//    
//    UInt8 *eightBitCasted = (UInt8 *)buffer;
//    UInt16 *sixteenBitCasted = (UInt16 *)buffer;
//    
//    for (NSInteger i = 0; i < length; i++) {
//        if(bits == 8)newBuffer[i] = eightBitCasted[i];
//        if(bits == 8)newBuffer[i] = (UInt8)(sixteenBitCasted[i]/255.0f);
//        newBuffer[i + 1] = newBuffer[i];
//        newBuffer[i + 2] = newBuffer[i];
//        if(bitsPerPixel/8 == 3)newBuffer[i + 3] = newBuffer[i];
//    }
//    
//    return newBuffer;
//}

+(CGImageRef)rawImageFromImage:(IMCImageStack *)imageStack index:(NSInteger)imageIndex numberOfBits:(int)bits{
    if(bits != 8 && bits != 16)return NULL;
    
    void *data = [IMCImageGenerator bufferImage:imageStack index:imageIndex bitsPerPixel:bits];
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    CFDataRef dataRef = CFDataCreate(NULL, data, imageStack.numberOfPixels * bits/8);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(dataRef);
    
    CGBitmapInfo bmInfo = bits == 8?kCGBitmapByteOrderDefault:kCGBitmapByteOrder16Little;
    
    CGImageRef imageRet = CGImageCreate(imageStack.width, imageStack.height, bits, bits, imageStack.width * bits/8, colorspace, bmInfo, provider, NULL, true, kCGRenderingIntentDefault);
    
    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);
    
    free(data);
    
    return imageRet;
}

#pragma mark Prepared Buffers

+(CGImageRef)imageWithRGBBuffer:(UInt8 *)buffer width:(NSInteger)width height:(NSInteger)height{
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CFDataRef rgbData = CFDataCreate(NULL, buffer, width * height * 3);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(rgbData);
    
    free(buffer);
    
    CGImageRef ref = CGImageCreate(width, height, 8, 24, width * 3, colorspace, kCGBitmapByteOrderDefault, provider, NULL, true, kCGRenderingIntentDefault);
    
    CFRelease(colorspace);
    CFRelease(rgbData);
    CFRelease(provider);
    
    return ref;
}

#pragma mark colorMask and Masks

+(CGImageRef)colorMask:(int *)mask numberOfColors:(NSInteger)colors  singleColor:(NSColor *)color width:(NSInteger)width height:(NSInteger)height{
    if (mask == NULL) {
        NSLog(@"Invalid array of data");
        return NULL;
    }
    
    UInt8 * pixelData = calloc(width * height * 3, sizeof(UInt8));
    
    NSColor *col = [color colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    for(int ui = 0; ui < width * height; ui++){
        if (mask[ui] == 0)continue;
        if(!color){
            float val = abs(mask[ui])%colors;
            float colorVal = 1.0f/6 + 1.0f/colors * (val - 1);
            if(colorVal > 1.0f)colorVal -= 1;
            col = [NSColor colorWithHue:colorVal saturation:1.0f brightness:1.0f alpha:1.0f];
        }
        
        pixelData[ui*3] = (int)(col.redComponent * 255);
        pixelData[ui*3+1] = (int)(col.greenComponent * 255);
        pixelData[ui*3+2] = (int)(col.blueComponent * 255);
        if(mask[ui] < 0){
            for (int j = 0; j < 3; j++)pixelData[ui*3+j] = pixelData[ui*3+j]/2;
        }
    }
    return [IMCImageGenerator imageWithRGBBuffer:pixelData width:width height:height];
}

+(UInt8 *)mapMaskTo255:(UInt8 *)mask length:(NSInteger)length toMax:(float)max{
    //float max = [IMCImageGenerator getMaxUInt8Buffer:mask withCounts:length];
    UInt8 * pixelData = calloc(length, sizeof(UInt8));
    for (NSInteger i = 0; i < length; i++) {
        pixelData[i] = (UInt8)MIN(255, mask[i]/max * 255);
    }
    return pixelData;
}

#pragma mark HUE and colors

RgbColor HsvToRgb(HsvColor hsv)
{
    RgbColor rgb;
    unsigned char region, remainder, p, q, t;
    
    if (hsv.s == 0)
    {
        rgb.r = hsv.v;
        rgb.g = hsv.v;
        rgb.b = hsv.v;
        return rgb;
    }
    
    region = hsv.h / 43;
    remainder = (hsv.h - (region * 43)) * 6;
    
    p = (hsv.v * (255 - hsv.s)) >> 8;
    q = (hsv.v * (255 - ((hsv.s * remainder) >> 8))) >> 8;
    t = (hsv.v * (255 - ((hsv.s * (255 - remainder)) >> 8))) >> 8;
    
    switch (region)
    {
        case 0:
            rgb.r = hsv.v; rgb.g = t; rgb.b = p;
            break;
        case 1:
            rgb.r = q; rgb.g = hsv.v; rgb.b = p;
            break;
        case 2:
            rgb.r = p; rgb.g = hsv.v; rgb.b = t;
            break;
        case 3:
            rgb.r = p; rgb.g = q; rgb.b = hsv.v;
            break;
        case 4:
            rgb.r = t; rgb.g = p; rgb.b = hsv.v;
            break;
        default:
            rgb.r = hsv.v; rgb.g = p; rgb.b = q;
            break;
    }
    
    return rgb;
}

HsvColor RgbToHsv(RgbColor rgb)
{
    HsvColor hsv;
    unsigned char rgbMin, rgbMax;
    
    rgbMin = rgb.r < rgb.g ? (rgb.r < rgb.b ? rgb.r : rgb.b) : (rgb.g < rgb.b ? rgb.g : rgb.b);
    rgbMax = rgb.r > rgb.g ? (rgb.r > rgb.b ? rgb.r : rgb.b) : (rgb.g > rgb.b ? rgb.g : rgb.b);
    
    hsv.v = rgbMax;
    if (hsv.v == 0)
    {
        hsv.h = 0;
        hsv.s = 0;
        return hsv;
    }
    
    
    hsv.s = 255 * (long)(rgbMax - rgbMin) / hsv.v;
    if (hsv.s == 0)
    {
        hsv.h = 0;
        return hsv;
    }
    
    if (rgbMax == rgb.r)
        hsv.h = 0 + 43 * (rgb.g - rgb.b) / (rgbMax - rgbMin);
    else if (rgbMax == rgb.g)
        hsv.h = 85 + 43 * (rgb.b - rgb.r) / (rgbMax - rgbMin);
    else
        hsv.h = 171 + 43 * (rgb.r - rgb.g) / (rgbMax - rgbMin);
    
    return hsv;
}

#pragma mark utilities

+(float)getMaxUInt8Buffer:(UInt8 *)array withCounts:(NSInteger)counts{
    int max = 0;
    for (int i = 0; i<counts; i++) {
        if (array[i] > max) {
            max = array[i];
        }
    }
    return (float)max;
}

@end
