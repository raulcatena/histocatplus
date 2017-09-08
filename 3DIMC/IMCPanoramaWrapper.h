//
//  IMCPanoramaWrapper.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCNodeWrapper.h"

@interface IMCPanoramaWrapper : IMCNodeWrapper

@property (nonatomic, strong) NSImage *panoramaImage;

-(BOOL)isPanorama;
-(NSString *)panoramaName;
-(float)widthPanorama;
-(float)heightPanorama;
-(NSMutableArray *)images;
-(NSImage *)panoramaImage;

@end
