//
//  IMCMatLabParser.m
//  IMCReader
//
//  Created by Raul Catena on 9/28/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCMatLabParser.h"

@implementation IMCMatLabParser


//Parse Matlab file http://se.mathworks.com/help/pdf_doc/matlab/matfile_format.pdf

#define DATA_OFFSET 136
#define DATA_HEADER_SIZE 56
#define DATA_HEADER_SIZE_ETH 68

+(void)parserMatLabData:(NSData *)data toInt32Buffer:(int *)buffer{

}

-(int)tests{
    
    char *buff = (char *)[self.matlabData bytes];
    short twoBytes;
    int fourBytes;
    int32_t dataInt;
    
    printf("\n");
    NSLog(@"\n__chars_mat header: 116\n\n");
    for (NSUInteger i = 0; i < 116; i++) {
        printf("%c", buff[i]);
    }
    printf("\n\n");
    NSLog(@"\nOffSets\n\n");
    for (NSUInteger i = 116; i < 124; i+=4) {
        [self.matlabData getBytes:&fourBytes range:NSMakeRange(i, 4)];
        printf("%i ", fourBytes);
    }
    printf("\n");
    NSLog(@"\n__version\n\n");
    [self.matlabData getBytes:&twoBytes range:NSMakeRange(124, 2)];
    printf("%i ", twoBytes);
    
    printf("\n");
    NSLog(@"\n__endian\n\n");
    printf("%c%c ", buff[126], buff[127]);
    printf("\n");
    
    printf("\n");
    NSLog(@"\n__data type\n\n");
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(128, 4)];
    printf("%i ", fourBytes);//14 means matlab array
    printf("\n");
    
    printf("\n");
    NSLog(@"\n__numberOfBytes\n\n");
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(132, 4)];
    printf("%i ", fourBytes);
    printf("\n");
    
    printf("\n");
    NSLog(@"\n__data_header\n\n");
    for (NSUInteger i = 136; i < 136 + 60; i++) {
        printf("%c -", buff[i]);
    }
    printf("\n");
    
    printf("\n");
    NSLog(@"\n__data_dimensions_4\n\n");
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(160, 4)];
    printf("%i ", fourBytes);
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(164, 4)];
    printf("%i ", fourBytes);
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(168, 4)];
    printf("%i ", fourBytes);
    printf("\n");
    
    printf("\n");
    NSLog(@"\n__proper_data\n\n");
    for (NSUInteger i = 192; i < self.matlabData.length; i+=4) {
        [self.matlabData getBytes:&dataInt range:NSMakeRange(i, 4)];
        //fourBytes = CFSwapInt32BigToHost((uint32)fourBytes);
        //printf("%i ", dataInt);
    }
    printf("\n");
    
    return 0;
}

-(NSInteger)dataType{
    
    int fourBytes;
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(128, 4)];
    return fourBytes;
}

-(NSInteger)numberOfBytes{
    
    int fourBytes;
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(132, 4)];
    return fourBytes;
}

-(NSInteger)heightMatrix{
    
    int fourBytes;
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(160, 4)];
    return fourBytes;
}

-(NSInteger)widthMatrix{
    
    int fourBytes;
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(164, 4)];
    return fourBytes;
}

-(NSInteger)channels{
    
    int fourBytes;
    [self.matlabData getBytes:&fourBytes range:NSMakeRange(168, 4)];
    return fourBytes;
}

-(void *)firstDataBeggining{
    char * byByte = (char *)self.matlabData.bytes;
    return &byByte[DATA_OFFSET];
}

-(int *)intBuffer{
    int * theData = (int *)[self firstDataBeggining];
    return &theData[DATA_HEADER_SIZE/sizeof(int)];
}

-(float *)floatBuffer{
    float * theData = (float *)[self firstDataBeggining];
    return &theData[DATA_HEADER_SIZE/sizeof(float)];
}

-(double *)doubleBuffer{
    double * theData = (double *)[self firstDataBeggining];
    return &theData[DATA_HEADER_SIZE/sizeof(double) + 3];
}

@end
