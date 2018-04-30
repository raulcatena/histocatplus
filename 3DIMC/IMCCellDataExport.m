//
//  IMCCellDataExport.m
//  3DIMC
//
//  Created by Raul Catena on 2/24/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCCellDataExport.h"
#import "IMCComputationOnMask.h"

@implementation IMCCellDataExport

+(BOOL)exportComputations:(NSArray<IMCComputationOnMask *> *)computations atPath:(NSString *)path channels:(NSIndexSet *)channels{
    IMCComputationOnMask *comp = computations.firstObject;
    for(IMCComputationOnMask *other in computations){
        if(!other.isLoaded)
            [other loadLayerDataWithBlock:nil];
        while (!other.isLoaded);
        if(other != comp)
            if (other.channels.count != comp.channels.count)
                return NO;
    }
    return [IMCCellDataExport saveDocumentAtPath:path computations:computations channels:channels];
}

+(NSString *)createNewHeader:(NSArray <IMCComputationOnMask *> *)computations  channels:(NSIndexSet *)channels fileName:(NSString *)fileName{
    /*
     FCS3.0 00 - 05
     ASCII(32) - space characters 06 - 09
     ASCII-encoded offset to first byte of TEXT segment 10 - 17
     ASCII-encoded offset to last byte of TEXT segment 18 - 25
     ASCII-encoded offset to first byte of DATA segment 26 - 33
     ASCII-encoded offset to last byte of DATA segment 34 - 41
     ASCII-encoded offset to first byte of ANALYSIS segment 42 - 49
     ASCII-encoded offset to last byte of ANALYSIS segment 50 - 57
     ASCII-encoded offset to user defined OTHER segments 58 - beginning of next segment
    */
    
    /*
     Required Keywords
     
     $BEGINANALYSIS    Byte-offset to the beginning of the ANALYSIS segment.
     $BEGINDATA    Byte-offset to the beginning of the DATA segment.
     $BEGINSTEXT    Byte-offset to the beginning of a supplemental TEXT segment.
     $BYTEORD    Byte order for data acquisition computer.
     $DATATYPE    Type of data in DATA segment (ASCII, integer, floating point).
     $ENDANALYSIS    Byte-offset to the end of the ANALYSIS segment.
     $ENDDATA    Byte-offset to the end of the DATA segment.
     $ENDSTEXT    Byte-offset to the end of a supplemental TEXT segment.
     $MODE    Data mode (list mode, histogram).
     $NEXTDATA    Byte offset to next data set in the file.
     $PAR    Number of parameters in an event.
     $PnB    Number of bits reserved for parameter number n.
     $PnE    Amplification type for parameter n.
     $PnR    Range for parameter number n.
     $TOT    Total number of events in the data set.
    */
    
    
    
    
    NSUInteger totalCells = 0;
    for(IMCComputationOnMask *comp in computations)
        totalCells += comp.segmentedUnits;
    NSUInteger sizeOfData = totalCells * channels.count * sizeof(float);
    
    IMCComputationOnMask *comp = computations.firstObject;
    
    float * maxs = calloc(comp.channels.count, sizeof(float));
    NSInteger numChans = channels.count;
    for(IMCComputationOnMask *comp in computations){
        float ** data = comp.computedData;
        NSInteger segments = comp.segmentedUnits;
        [channels enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
            for (NSInteger j = 0; j < segments; ++j)
                if(data[i][j] > maxs[i])
                    maxs[i] = data[i][j];
        }];
    }
    
    NSString * lengthData = [NSString stringWithFormat:@"%lu", sizeOfData];
    NSInteger lengthDataAsText = lengthData.length;
    
    NSString *newHeader = @"FCS3.0          77*lbts**fbds**lbds*       0       0                   ";
    
    NSMutableString *intermediate = @"/$FIL/*file*/$MODE/L/$DATATYPE/F/$BYTEORD/1,2,3,4/$PAR/*pars*/$TOT/*total*/$BEGINSTEXT/0/$ENDSTEXT/0/$NEXTDATA/0/$BEGINANALYSIS/0/$ENDANALYSIS/0/".mutableCopy;//$BEGINDATA/##/$ENDDATA/
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@" " withString:@""];
    intermediate = [intermediate stringByReplacingOccurrencesOfString:@"*file*" withString:fileName].mutableCopy;
    intermediate = [intermediate stringByReplacingOccurrencesOfString:@"*pars*" withString:[NSString stringWithFormat:@"%li", numChans]].mutableCopy;
    intermediate = [intermediate stringByReplacingOccurrencesOfString:@"*total*" withString:[NSString stringWithFormat:@"%li", totalCells]].mutableCopy;
    
    __block NSInteger counter = 1;
    [channels enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop){
        NSString *chan = comp.channels[i];
        chan = [chan stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
        chan = [chan stringByReplacingOccurrencesOfString:@" " withString:@"_"];
//        chan = [chan stringByReplacingOccurrencesOfString:@"(" withString:@"_"];
//        chan = [chan stringByReplacingOccurrencesOfString:@")" withString:@"_"];
//        NSString *orig = comp.channels[i];
//        orig = [orig stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
//        orig = [[orig stringByReplacingOccurrencesOfString:@" " withString:@"_"]substringToIndex:MIN(4, orig.length - 1)];
        [intermediate appendFormat:@"$P%liS/%@/$P%liB/%li/$P%liE/0,0/$P%liR/%li/",//$P%liN/%@/
         counter,
         chan,
         //counter,
         //[chan substringToIndex:MIN(6, chan.length - 1)],
         counter,
         32L,
         counter,
         counter,
         (NSInteger)maxs[i]];
        counter++;
    }];
    
    NSInteger lengthMiddle = intermediate.length;
    
    NSInteger endText = 77 + lengthMiddle + 22 + (lengthDataAsText + 1) * 2;
    NSInteger startData, endData;
    
    NSString *endTextChars;
    NSString *startDataChars;
    NSString *endDataChars;
    
    NSInteger endTextCharsLenght, startDataCharsLenght, endDataCharsLenght;
    
    NSString *appended;
    do  {
        startData = endText + 1;
        endData = endText + sizeOfData;
        
        endTextChars = [NSString stringWithFormat:@"%li", endText];
        startDataChars = [NSString stringWithFormat:@"%li", startData];
        endDataChars = [NSString stringWithFormat:@"%li", endData];
        
        endTextCharsLenght = endTextChars.length;
        startDataCharsLenght = startDataChars.length;
        endDataCharsLenght = endDataChars.length;
        
        NSString *prep = [NSString stringWithFormat:@"/$BEGINDATA/%@/$ENDDATA/%@", startDataChars, endDataChars];
        appended =  [prep stringByAppendingString:intermediate];
//        appended =  [intermediate stringByReplacingOccurrencesOfString:@"/$ENDANALYSIS/0/" withString:
//                     [NSString stringWithFormat:@"/$ENDANALYSIS/0/$BEGINDATA/%@/$ENDDATA/%@/", startDataChars, endDataChars]];
        endText--;
    }while (startData > 77 + appended.length);
    
    while (endTextChars.length < 8)
        endTextChars = [@" " stringByAppendingString:endTextChars];
    newHeader = [newHeader stringByReplacingOccurrencesOfString:@"*lbts*" withString:endTextChars];
    
    while (startDataChars.length < 8)
        startDataChars = [@" " stringByAppendingString:startDataChars];
    newHeader = [newHeader stringByReplacingOccurrencesOfString:@"*fbds*" withString:startDataChars];
    
    while (endDataChars.length < 8)
        endDataChars = [@" " stringByAppendingString:endDataChars];
    newHeader = [newHeader stringByReplacingOccurrencesOfString:@"*lbds*" withString:endDataChars];
    
    return [newHeader stringByAppendingString:appended];
}

+(BOOL)saveDocumentAtPath:(NSString *)path computations:(NSArray <IMCComputationOnMask *> *)computations channels:(NSIndexSet *)channels{

    NSString *fileName = [path.lastPathComponent stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableString *beggining = [IMCCellDataExport createNewHeader:computations channels:channels fileName:fileName].mutableCopy;
    
    NSMutableData *data = [beggining dataUsingEncoding:NSASCIIStringEncoding].mutableCopy;
    
    NSUInteger sizeOfData = 0;
    for(IMCComputationOnMask *comp in computations)
        sizeOfData += comp.segmentedUnits * channels.count * sizeof(float);
    
    NSMutableData *rawDataToSave = [NSMutableData dataWithCapacity:sizeOfData];//Is actually a bit more
    
    for(IMCComputationOnMask *comp in computations){
        NSInteger units = comp.segmentedUnits;
        float ** data = comp.computedData;
        for(NSInteger i = 0; i < units; ++i){
            [channels enumerateIndexesUsingBlock:^(NSUInteger j, BOOL *stop){
                float val = data[j][i];
                [rawDataToSave appendBytes:&val length:sizeof(float)];
            }];
        }
    }
    
    [data appendData:rawDataToSave];
    
    char dataByesCloseFile[8] = {0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30};
    [data appendBytes:&dataByesCloseFile length:8];
    
    NSError *error = nil;
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    NSString * desktopPath = [paths objectAtIndex:0];
    NSLog(@"Will write to %@", path);
    NSLog(@"Will write to %@", [[desktopPath stringByAppendingString:@"/" ] stringByAppendingString:path.lastPathComponent]);
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    
    return error ? NO : YES;
}


@end
