//
//  IMCCellDataExport.m
//  3DIMC
//
//  Created by Raul Catena on 2/24/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellDataExport.h"

@implementation IMCCellDataExport


-(NSString *)createNewHeader{
//    NSUInteger sizeOfData = fileLines * _channelsShortName.count * sizeof(uint32_t);
//    
//    NSArray *array = [_header componentsSeparatedByString:@"$P1"];
    NSMutableString *beggining;// = [array.firstObject mutableCopy];
    
//    for (int i = 1; i< _channelsShortName.count + 1 ; i++) {
//        NSString *shortChannel = [_channelsShortName objectAtIndex:i - 1];
//        NSString *longChannel = [_channelsLongName objectAtIndex:i- 1];
//        NSString *bitsChannel = [_bitsInitial objectAtIndex:i- 1];
//        NSString *rangeChannel = [_rangeInitial objectAtIndex:i - 1];
//        NSString *ampInitial = [_ampInitial objectAtIndex:i- 1];
//        [beggining appendFormat:@"$P%iN/%@/$P%iS/%@/$P%iB/%@/$P%iE/%@/$P%iR/%@/",
//         i,
//         [shortChannel stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//         i,
//         [longChannel stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//         i,
//         bitsChannel,
//         i,
//         ampInitial,
//         i,
//         rangeChannel];
//    }
//    
//    [self parameters:beggining];
//    NSLog(@"New generated file %@", beggining);
//    [self substituteBeggining:beggining withValue:beggining.length];
//    [self substituteBeggining:beggining withValue:beggining.length];
//    [self substituteEnding:beggining withValue:beggining.length + sizeOfData];
//    [self substituteEnding:beggining withValue:beggining.length + sizeOfData];
    
    return beggining;
}

-(void)saveDocumentAtPath:(NSString *)path{
//    NSMutableString *beggining = [self createNewHeader].mutableCopy;
//    NSMutableData *data = [beggining dataUsingEncoding:NSASCIIStringEncoding].mutableCopy;
//    NSMutableData *rawDataToSave = [NSMutableData dataWithCapacity:initialDataEnd];//Is actually a bit more
    
//    for (int j = 0; j<fileLines; j++) {
//        for (int i = 0; i < _channelsShortName.count; i++) {
//            [rawDataToSave appendBytes:&rawData[i][j] length:sizeof(uint32_t)];
//        }
//    }
//    [data appendData:rawDataToSave];
//    char dataByesCloseFile[8] = {0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30};
//    [data appendBytes:&dataByesCloseFile length:8];
//    
//    NSError *error = nil;
//    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
//    NSString * desktopPath = [paths objectAtIndex:0];
//    NSLog(@"Will write to %@", path);
//    NSLog(@"Will write to %@", [[desktopPath stringByAppendingString:@"/" ] stringByAppendingString:self.fileURL.lastPathComponent]);
//    [data writeToFile:path options:NSDataWritingAtomic error:&error];
//    //[array writeToFile:[NSString stringWithFormat:@"%@/%@", desktopPath, fileTitle] atomically:YES];
//    if(error)NSLog(@"Write returned error: %@", [error localizedDescription]);
}

-(void)saveDocumentAsOV:(NSButton *)sender{
//    NSSavePanel * savePanel = [NSSavePanel savePanel];
//    [savePanel setAllowedFileTypes:@[@"fcs"]];
//    
//    [savePanel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
//        if (result == NSFileHandlingPanelOKButton) {
//            // Close panel before handling errors
//            [savePanel orderOut:self];
//            [self saveDocumentAtPath:savePanel.URL.path];
//        }
//    }];
}

@end
