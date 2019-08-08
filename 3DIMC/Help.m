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
    if([Help respondsToSelector:NSSelectorFromString(identifier)])
        [Help performSelectorOnMainThread:NSSelectorFromString(identifier) withObject:nil waitUntilDone:YES];
}

+(void)helpPlots{
    [General runHelpModalWithMessage:@"For this to work you need to install R (No R Studio is necessary). Install R with the default installation destination for MacOS (/Library/Frameworks/R.framework) Go to the R console and make sure ggplot2 and RColorBrewer are installed. If you need to install these 2 packages, just type:\
        \n\n>install.packages('devtools');\
        \n\n>require('devtools');\
        \n\n>install_version('ggplot2', version = '2.1.0', repos = 'http://cran.us.r-project.org');\
        \n\n>devtools::install_github('cran/ggplot2', force = TRUE);\
        \n\n>install.packages(\"RColorBrewer\");\
        \n\n(Do not copy the '>' symbol)\nSelect the mirror and the package should get installed just doing this." andTitle:@"Help plots"];
}
+(void)helpBinaryExport{
    [General runHelpModalWithMessage:@"Exports data as float32 binary, followed by a tab-separated UTF-8 string with the names of the channels. The first value is the number of cells, the second is the number of channels, the thrid is the offset of the UTF-8 string. From value 4 until the offset the binary data organized as cell_1_channel_1, cell_1_channel_2 ... cell_1_channel_n | then cell_2_channel_1 etc. ONLY the channels selected in the channels table will be exported. A cell_id and Acquisition column is also added automatically" andTitle:@"Help Binary Export"];
}
+(void)helpCompensation{
    [General runHelpModalWithMessage:@"Read Chevrier et al. 2018 on how compensation works. If you switch this on, the matrix published by Chevrier will be applied to your data to compensate. You can also go to the Edit menu and input a custom compensation matrix if you have the spillover matrix for your isotope set in your own hands. One requierment for this function to work is that anywhere in the channel names the metals are specified, such as Eu151. The channel naming is automatized if you use AirLab (Catena et al. 2016)" andTitle:@"Help Compensation"];
}

@end
