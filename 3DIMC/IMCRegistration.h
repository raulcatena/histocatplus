//
//  IMCRegistration.h
//  3DIMC
//
//  Created by Raul Catena on 2/1/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>
//https://blogs.wcode.org/2014/11/howto-setup-xcode-6-1-to-work-with-opencv-libraries/



@interface IMCRegistration : NSObject
//+(CGImageRef)startRegistration:(NSInteger *)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep xRange:(NSInteger)xTranslationRange yRange:(NSInteger)yTranslationRange destDict:(NSMutableDictionary *)dest inelasticBrush:(NSInteger)brushIneslastic elasticBrush:(NSInteger)brushElastic;
+(CGImageRef)startRegistration:(NSInteger *)capture sourceImage:(CGImageRef)sourceImg targetImage:(CGImageRef)targetImg angleRange:(float)angleRange angleStep:(float)angleStep destDict:(NSMutableDictionary *)dest inelasticBrush:(NSInteger)brushIneslastic elasticBrush:(NSInteger)brushElastic exactMatches:(BOOL)exact;
@end
