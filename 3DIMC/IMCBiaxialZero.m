//
//  IMCBiaxialZero.m
//  IMCReader
//
//  Created by Raul Catena on 9/13/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCBiaxialZero.h"
#import "NSArray+Statistics.h"

@implementation IMCBiaxialZero

int fltcompare(const void *a,const void *b) {
    float fa, fb;
    fa = * ((float *) a);
    fb = * ((float *) b);
    if(fa > fb) return 1;
    if(fa < fb) return -1;
    return 0;
}

-(void)drawPoints:(CGContextRef)ctx dirtyRect:(CGRect)dirtyRect{
    
    float *theBiaxialData = [self.delegatePlot floatBiaxialData];
    if(!theBiaxialData)return;
    int dataSize = [self.delegatePlot sizeOfData];
    int elements = dataSize/2;
    float width = dirtyRect.size.width * 0.9;
    float height = dirtyRect.size.height * 0.9;
    
    CGContextSetLineWidth(ctx,self.sizePoints * 2);
    CGContextSetRGBStrokeColor(ctx, self.pointsColor.redComponent,
                               self.pointsColor.greenComponent,
                               self.pointsColor.blueComponent,
                               self.transparencyPoints);
    
    
    float * x = malloc(elements * sizeof(float));
    float * y = malloc(elements * sizeof(float));
    for (NSInteger i = 0; i < dataSize; i+= 2) {
        x[i/2] = theBiaxialData[i];
        y[i/2] = theBiaxialData[i + 1];
    }
    NSInteger validX = 0, validY = 0;
    for (NSInteger i = 0; i < elements; i++) {
        if(!isnan(x[i]) || !isinf(ABS(x[i])))validX++;
        if(!isnan(y[i]) || !isinf(ABS(y[i])))validY++;
    }
    qsort (x, elements, sizeof(float), fltcompare);
    qsort (y, elements, sizeof(float), fltcompare);
    
    NSInteger pre = (NSInteger)validX * 100;
    NSInteger preIndex = pre / 10000;
    NSInteger post = (NSInteger)validY * 9900;
    NSInteger postIndex = post / 10000;
    
    
    self.minX = x[preIndex];
    self.minY = y[preIndex];
    self.maxX = x[postIndex];
    self.maxY = y[postIndex];

    free(x);
    free(y);
    
//    self.maxX = 0; self.maxY = 0; self.minX = 0; self.minY = 0;
    
//    NSLog(@"MX MY MxX MxY %f %f %f %f", self.minX, self.minY, self.maxX, self.maxY);
//    for (NSInteger x = 0; x<dataSize; x+=2) {
//        if(isnan(theBiaxialData[x]) || isinf(ABS(theBiaxialData[x])))continue;
//        if(theBiaxialData[x] > self.maxX)self.maxX = theBiaxialData[x];
//        if(theBiaxialData[x] < self.minX)self.minX = theBiaxialData[x];
//        if(isnan(theBiaxialData[x + 1]) || isinf(ABS(theBiaxialData[x + 1])))continue;
//        if(theBiaxialData[x+1] > self.maxY)self.maxY = theBiaxialData[x+1];
//        if(theBiaxialData[x+1] < self.minY)self.minY = theBiaxialData[x+1];
//    }
//    
//    NSLog(@"-MX MY MxX MxY %f %f %f %f", self.minX, self.minY, self.maxX, self.maxY);

    float plotableX = (width - 1.2 * self.cornerMargin);
    float plotableY = (height - 1.2 * self.cornerMargin);
    float rangeX = self.maxX - self.minX;
    float rangeY = self.maxY - self.minY;
    
    float internalX = plotableX * fabsf(self.minX)/(self.maxX - self.minX);
    float internalY = plotableY * fabsf(self.minY)/(self.maxY - self.minY);
    
    
    int *dataColor = [self.delegatePlot colorDataForThirdDimension];
    if(dataColor != NULL)[self addTopLabel:[self.delegatePlot topLabel] context:ctx dirtyRect:dirtyRect];
    
    BOOL heatColor = [self.delegatePlot heatColorMode];
    
    RgbColor rgb;
    rgb.r = (int)self.pointsColor.redComponent * 255;
    rgb.g = (int)self.pointsColor.greenComponent * 255;
    rgb.b = (int)self.pointsColor.blueComponent * 255;
    
    for (NSInteger x = 0; x<dataSize; x+=2) {
        //printf("datico %f %f\n", theBiaxialData[x], theBiaxialData[x+1]);
        if (theBiaxialData[x] == .0f && theBiaxialData[x + 1] == .0f)continue;
        if (isnan(theBiaxialData[x]) || isnan(theBiaxialData[x + 1]))continue;
        if (isinf(ABS(theBiaxialData[x])) || isinf(ABS(theBiaxialData[x + 1])))continue;
        if(dataColor != NULL){
            if(heatColor == YES){
                HsvColor hsv;
                hsv.h = 170 - dataColor[x/2 * 3]/3 * 2;
                hsv.s = 255;
                hsv.v = 255;
                rgb = HsvToRgb(hsv);
                
                CGContextSetRGBStrokeColor(ctx,
                                           rgb.r/255.0f,
                                           rgb.g/255.0f,
                                           rgb.b/255.0f,
                                           self.transparencyPoints);
            }else{

                rgb.r = dataColor[x/2 * 3 + 0];
                rgb.g = dataColor[x/2 * 3 + 1];
                rgb.b = dataColor[x/2 * 3 + 2];
                
                CGContextSetRGBStrokeColor(ctx,
                                           rgb.r/255.0f,
                                           rgb.g/255.0f,
                                           rgb.b/255.0f,
                                           self.transparencyPoints);
            }
            
        }
        //CGContextSaveGState(ctx);
        float posX = self.cornerMargin * 1.2 + internalX + theBiaxialData[x] * plotableX/rangeX;
        float posY = self.cornerMargin * 1.2 + internalY + theBiaxialData[x+1] * plotableY/rangeY;
        
        //if(posX < self.maxX && posX > self.minX && posY < self.maxY && posY > self.minY){
            CGContextAddArc(ctx,
                            posX,
                            posY,
                            self.sizePoints,
                            0.0f,
                            M_PI*2,
                            YES);
            CGContextStrokePath(ctx);
            CGContextFillPath(ctx);
        //}
    }
    [self maxLabels:ctx];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGContextRef ctx= [[NSGraphicsContext currentContext] graphicsPort];
    [self setBackGroundColor:ctx dirtyRect:dirtyRect];
    [self drawAxes:ctx];
    [self drawLabels:ctx];
    [self drawPoints:ctx dirtyRect:dirtyRect];
}

@end
