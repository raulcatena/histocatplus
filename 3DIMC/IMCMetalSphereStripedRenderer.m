//
//  IMCMetalSphereStripedRenderer.m
//  3DIMC
//
//  Created by Raul Catena on 11/20/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCMetalSphereStripedRenderer.h"

@implementation IMCMetalSphereStripedRenderer

-(void)updateColorBuffer{
    
    self.cellsToRender = 0;
    float ** data = [self.computation computedData];
    if(data){
        AlphaMode alphaMode = [self.delegate alphaMode];
        
        NSInteger segments = self.computation.segmentedUnits;
        NSInteger channels = self.indexesObtained.count;
        self.stripes = MIN(channels, 10);
        NSInteger copyStripes = self.stripes;
        NSInteger stride = 4 + self.stripes * 4;
        
        float * buff = calloc(segments * stride, sizeof(float));
        if(buff){
            self.colorsObtained = [self.delegate colors];
            float minThresholdForAlpha = [self.delegate combinedAlpha];
            
            float * colors = (float *)malloc(self.colorsObtained.count * 3 * sizeof(float));
            
            for (int i = 0; i< self.colorsObtained.count; i++) {
                NSColor *colorObj = [self.colorsObtained objectAtIndex:i];
                colorObj = [colorObj colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
                colors[i * 3] = colorObj.redComponent/255.0f;
                colors[i * 3 + 1] = colorObj.greenComponent/255.0f;
                colors[i * 3 + 2] = colorObj.blueComponent/255.0f;
            }
            
            float * xCentroids = [self.computation xCentroids];
            float * yCentroids = [self.computation yCentroids];
            float * zCentroids = [self.computation zCentroids];
            
            float minZ = [self.computation minDimension:2];
            
            float defaultThicknessValue = [self.delegate defaultThicknessValue];
            if(minZ < .0f)
                defaultThicknessValue = 1.0f;
            
            float * sizes = [self.computation sizes];
            
            float cellModifier = [self.delegate cellModifierFactor];
            float maxes[channels];
            for (NSInteger idx = 0; idx < channels; idx++)
                maxes[idx] = [self.computation maxChannel:[self.indexesObtained[idx]integerValue]];
            
            //int allInts [10] = {405, 162, 162, 162, 162, 162, 162, 162, 162, 243};
            
            for (NSInteger i = 0; i < segments; i++) {
                
                NSInteger internalCursor = i * stride;
                
                buff[internalCursor + 0] = xCentroids[i];
                buff[internalCursor + 1] = yCentroids[i];
                buff[internalCursor + 2] = zCentroids[i] * defaultThicknessValue;
                buff[internalCursor + 3] = powf((3 * sizes[i]) / (4 * M_PI) , 1.0f/3) * cellModifier;//Size
                
                NSInteger channelOffset = 4;
                for (NSInteger idx = 0; idx < copyStripes; idx++) {
                    
                    NSInteger realIndex = [self.indexesObtained[idx]integerValue];
                    
                    UInt8 val = (UInt8)((data[realIndex][i]/maxes[idx]) * 255.0f);
                    if(self.colorsObtained.count > 0){
                        buff[internalCursor + channelOffset + 1] = val * colors[idx * 3];
                        buff[internalCursor + channelOffset + 2] = val * colors[idx * 3 + 1];
                        buff[internalCursor + channelOffset + 3] = val * colors[idx * 3 + 2];
                    }else{
                        RgbColor rgb = RgbFromFloatUnit(val/255.0f);
                        buff[internalCursor + channelOffset + 1] = rgb.r/255.0f;
                        buff[internalCursor + channelOffset + 2] = rgb.g/255.0f;
                        buff[internalCursor + channelOffset + 3] = rgb.b/255.0f;
                    }
                    
                    //Filters
                    float max = .0f;
                    float sum = .0f;
                    for (int j = 1; j < 4; j++){
                        float val = buff[internalCursor + channelOffset + j];
                        if(val > max)
                            max = val;
                        sum += val;
                        if(sum > 1.0f){
                            sum = 1.0f;
                            break;
                        }
                    }
                    
                    if(alphaMode == ALPHA_MODE_OPAQUE)
                        buff[internalCursor + channelOffset] = max < minThresholdForAlpha ? 0.0f : 1.0f;
                    if(alphaMode == ALPHA_MODE_FIXED)
                        buff[internalCursor + channelOffset] = max < minThresholdForAlpha ? 0.0f : minThresholdForAlpha;//Alpha
                    if(alphaMode == ALPHA_MODE_ADAPTIVE)
                        buff[internalCursor + channelOffset] = max < minThresholdForAlpha ? 0.0f : sum;//MIN(1.0f, sum);//Alpha
                    
                    channelOffset += 4;
                }
            }
            NSInteger bufferSize = segments * stride;
            float * cleanBuffer = malloc(bufferSize * sizeof(float));
            
            //Remove all Zeroes
            NSInteger cleanIndex = 0;
            for (NSInteger m = 0; m < bufferSize; m+=stride){
                BOOL renderCell = NO;
                for (NSInteger c = 0; c < self.stripes; c++)
                    if(buff[m + 4 + c * 4] > 0)
                        renderCell = YES;
                if(renderCell){
                    for (NSInteger j = 0; j < stride; j++)
                        cleanBuffer[cleanIndex + j] = buff[m + j];
                    cleanIndex += stride;
                }
            }
            
            self.cellsToRender = cleanIndex/stride;
            cleanBuffer = realloc(cleanBuffer, sizeof(float) * cleanIndex);
            self.colorBuffer = [self.device newBufferWithBytes:cleanBuffer length:cleanIndex * sizeof(float) options:MTLResourceOptionCPUCacheModeDefault];
            
            NSLog(@"-%li", self.cellsToRender);
            
            free(buff);
            free(cleanBuffer);
            free(colors);
        }
    }
}

-(void)createMetalStack{
    [self addSphereVertexBuffer];
    
    //Create pipeline state
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"stripedSphereVertexShader"];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"sphereFragmentShader"];
    
    MTLRenderPipelineDescriptor * pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexProgram;
    pipelineDescriptor.fragmentFunction = fragmentProgram;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.colorAttachments[0].blendingEnabled = YES;
    
    pipelineDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    
    pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    //Expensive. Do least possible
    NSError *error;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if(error)
        NSLog(@"Some error %@ %@", error, error.localizedDescription);
    
    self.commandQueue = [self.device newCommandQueue];
    
    //Stencil
    MTLDepthStencilDescriptor * desc = [MTLDepthStencilDescriptor new];
    desc.depthCompareFunction = MTLCompareFunctionLess;
    desc.depthWriteEnabled = YES;
    self.stencilState = [self.device newDepthStencilStateWithDescriptor:desc];
}

@end
