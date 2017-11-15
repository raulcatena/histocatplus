//
//  General.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "General.h"

@implementation General

+(BOOL)isDirectory:(NSURL *)url{
    NSNumber *isDirectory;
    BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
    if (success && [isDirectory boolValue]) {
        return YES;
    } else {
        return NO;
    }
}

+(NSInteger)runAlertModalAreYouSure{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = @"Are you sure";
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    return [alert runModal];
}

+(NSInteger)runAlertModalAreYouSureWithMessage:(NSString *)message{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = message;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    
    return [alert runModal];
}

+(NSInteger)runAlertModalWithMessage:(NSString *)message{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = message;
    [alert addButtonWithTitle:@"OK"];
    return [alert runModal];
}
+(NSInteger)runHelpModalWithMessage:(NSString *)message andTitle:(NSString *)title{
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    return [alert runModal];
}

+(void)drawIntAsString:(float)number WithFontName:(NSString *)fontName size:(float)size rect:(CGRect)rect{

    NSFont *font = [NSFont fontWithName:@"Helvetica" size:size];
    NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSTextAlignmentCenter];
    [[NSString stringWithFormat:@"%g", number]
     drawInRect:rect withAttributes:
     
     @{
       NSForegroundColorAttributeName: [NSColor darkGrayColor],
       NSFontAttributeName: font,
       NSParagraphStyleAttributeName: style
       }
     ];
}

+(void)checkAndCreateDirectory:(NSString *)path{
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:path isDirectory:&isDir])
        if(![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@", path);
}

+(void)orderIndexesUponSelection:(NSMutableArray *)orderedArray indexes:(NSIndexSet *)indexSet{
    if(!orderedArray)orderedArray = @[].mutableCopy;
    
    //Add non present ones
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
        if(![orderedArray containsObject:[NSNumber numberWithInteger:idx]])
            [orderedArray addObject:[NSNumber numberWithInteger:idx]];
    }];
    
    //Find gone ones from selection
    for (NSNumber *num in orderedArray.copy) {
        if(![indexSet containsIndex:num.integerValue])
            [orderedArray removeObject:num];
    }
}

+(void)addArrayOfStrings:(NSArray *)arrayStr toNSPopupButton:(NSPopUpButton *)button noneAtBeggining:(BOOL)none{
    [button removeAllItems];
    NSMutableArray *titles = button.itemTitles.mutableCopy;
    NSInteger prevSelected = button.indexOfSelectedItem;
    if(none)
        if(![titles containsObject:@"None"])
            [titles insertObject:@"None" atIndex:0];
    for (NSString *str in arrayStr) {//TODO refactor this
        if(![titles containsObject:str])
            [titles addObject:str];
    }
    [button removeAllItems];
    for (NSString *str in titles) {//TODO refactor this
        [button addItemWithTitle:@"blah"];
        [[button lastItem]setTitle:str];
    }
    if(prevSelected != NSNotFound && prevSelected < titles.count)
        [button selectItemAtIndex:prevSelected];
}

+(NSString*)jsonStringFromObject:(id)object prettryPrint:(BOOL)prettyPrint{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (! jsonData) {
        return @"";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
+(id)objectFromString:(NSString *)string{
    return [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:0 error:NULL];
}
//Tie computations
+(NSIndexSet *)cellComputations{
    return [IMCUtils inputTable:@[
                                                      @"Cell Total",
                                                      @"Cell Mean",
                                                      @"Cell Median",
                                                      @"Cell Standard Deviation",
                                                      @"Nucleus Total",
                                                      @"Nucleus Mean",
                                                      @"Nucleus Median",
                                                      @"Nucleus Standard Deviation",
                                                      @"Cytoplasm Total",
                                                      @"Cytoplasm Mean",
                                                      @"Cytoplasm Median",
                                                      @"Cytoplasm Standard Deviation",
                                                      @"Ratio Cyt/Nuc Total",
                                                      @"Ratio Cyt/Nuc Mean",
                                                      @"Ratio Cyt/Nuc Median",
                                                      @"Ratio Cyt/Nuc Standard Deviation",
                                                      ] prompt:@"Select computations to perform"];
}


@end
