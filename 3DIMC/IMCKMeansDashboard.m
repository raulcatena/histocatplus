//
//  IMCKMeansDashboard.m
//  IMCReader
//
//  Created by Raul Catena on 9/17/16.
//  Copyright © 2016 CatApps. All rights reserved.
//

#import "IMCKMeansDashboard.h"

@implementation IMCKMeansDashboard

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)changed:(id)sender{
    if(sender == self.clusters)self.clustersField.intValue = self.clusters.intValue;
    if(sender == self.restarts)self.restartsField.intValue = self.restarts.intValue;
}

@end
