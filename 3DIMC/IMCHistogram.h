//
//  IMCHistogram.h
//  histoCAT Viewer
//
//  Created by Raul Catena on 3/29/18.
//  Copyright © 2018 CatApps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface IMCHistogram : NSView
@property (nonatomic, assign) unsigned bitsAmplitude;
-(void)primeWithData:(UInt8 **)data channels:(NSInteger)channels pixels:(NSInteger)pixels colors:(NSArray *)colors;

@end
