//
//  IMCMatLabParser.h
//  IMCReader
//
//  Created by Raul Catena on 9/28/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IMCMatLabParser : NSObject

@property (nonatomic, strong) NSData * matlabData;

+(void)parserMatLabData:(NSData *)data toInt32Buffer:(int *)buffer;
-(NSInteger)dataType;
-(NSInteger)heightMatrix;
-(NSInteger)widthMatrix;
-(NSInteger)channels;
-(NSInteger)numberOfBytes;
-(int *)intBuffer;
-(float *)floatBuffer;
-(double *)doubleBuffer;
@end
