//
//  IMCButtonLayer.m
//  3DIMC
//
//  Created by Raul Catena on 3/1/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCButtonLayer.h"

@implementation IMCButtonLayer

-(void)setParent:(IMCButtonLayer *)parent{
    if(!parent){
        if([_parent.children containsObject:self])
           [_parent.children removeObject:self];
    }
    _parent = parent;
    if(!parent.children)parent.children = @[].mutableCopy;
    [parent.children addObject:self];
}

-(NSString *)nameForOption{
    NSString *name;
    switch (self.type) {
        case 1:
            name = @"Raw Pixel Data";
            break;
        case 2:
            name = @"Gaussian Blur 3x3 kernel";
            break;
        case 3:
            name = @"Gaussian Blur 5x5 kernel";
            break;
        case 4:
            name = @"Gaussian Blur 7x7 kernel";
            break;
        case 5:
            name = @"Gaussian Blur 9x9 kernel";
            break;
        case 6:
            name = @"Gaussian Blur 11x11 kernel";
            break;
        case 7:
            name = @"Gaussian Blur 21x21 kernel";
            break;
        case 8:
            name = @"Gaussian Blur 51x51 kernel";
            break;
        case 9:
            name = @"Laplacian Blur 3x3 kernel";
            break;
        case 10:
            name = @"Laplacian Blur 5x5 kernel";
            break;
        case 11:
            name = @"Laplacian Blur 7x7 kernel";
            break;
        case 12:
            name = @"Laplacian Blur 9x9 kernel";
            break;
        case 13:
            name = @"Laplacian Blur 11x11 kernel";
            break;
        case 14:
            name = @"Laplacian Blur 21x21 kernel";
            break;
        case 15:
            name = @"Laplacian Blur 51x51 kernel";
            break;
        case 16:
            name = @"Canny edge 3x3 kernel";
            break;
        case 17:
            name = @"Canny edge 5x5 kernel";
            break;
        case 18:
            name = @"Canny edge 7x7 kernel";
            break;
        case 19:
            name = @"Canny edge 9x9 kernel";
            break;
        case 20:
            name = @"Canny edge 11x11 kernel";
            break;
        case 21:
            name = @"Canny edge 21x21 kernel";
            break;
        case 22:
            name = @"Canny edge 51x51 kernel";
            break;
        case 23:
            name = @"Gaussian Gradient 3x3 kernel";
            break;
        case 24:
            name = @"Gaussian Gradient 5x5 kernel";
            break;
        case 25:
            name = @"Gaussian Gradient 7x7 kernel";
            break;
        case 26:
            name = @"Gaussian Gradient 9x9 kernel";
            break;
        case 27:
            name = @"Gaussian Gradient 11x11 kernel";
            break;
        case 28:
            name = @"Gaussian Gradient 21x21 kernel";
            break;
        case 29:
            name = @"Gaussian Gradient 31x31 kernel";
            break;
        default:
            name = @"Default";
            break;
    }
    return name;
}

@end
