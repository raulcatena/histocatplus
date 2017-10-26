//
//  IMCTsneDashboard.m
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCTsneDashboard.h"

@implementation IMCTsneDashboard


-(void)changed:(id)sender{
    self.perplexityField.floatValue = self.perplexity.floatValue;
}

@end
