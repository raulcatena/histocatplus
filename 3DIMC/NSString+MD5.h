//
//  NSString+MD5.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MD5)
- (NSString*)MD5;
- (NSString *)sanitizeFileNameString;
@end
