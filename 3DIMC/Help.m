//
//  Help.m
//  3DIMC
//
//  Created by Raul Catena on 11/10/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "Help.h"

@implementation Help

+(void)helpWithIdentifier:(NSString *)identifier{
    if([identifier isEqualToString:@"helpPlots"])
        [Help helpPlots];
}

+(void)helpPlots{
    [General runHelpModalWithMessage:@"For this to work you need to install R (No R Studio is necessary). Install R with the default installation destination for MacOS (/Library/Frameworks/R.framework) Go to the R console and make sure ggplot2 and RColorBrewer are installed. If you need to install these 2 packages, just type:\n\n>install.packages(\"ggplot2\")\n\n>install.packages(\"RColorBrewer\")\n\n(Do not copy the '>' symbol)\nSelect the mirror and the package should get installed just doing this." andTitle:@"Help plots"];
}

@end
