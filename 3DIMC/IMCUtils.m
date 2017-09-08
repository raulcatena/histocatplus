//
//  IMCUtils.m
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCUtils.h"

@implementation IMCUtils

+(NSString *)randomStringOfLength:(int)length{
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0; i < length; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return [NSString stringWithString:s];
}
+(float)sumOfSquareDistancesPointArray:(NSArray *)array{//Array of NSValue points
    float sumX = .0f;
    float sumY = .0f;
    for (NSValue *value in array) {
        CGPoint point = value.pointValue;
        sumX += point.x;
        sumY += point.y;
    }
    float avgX = sumX/array.count;
    float avgY = sumY/array.count;
    
    float sumOfDistances = .0f;
    for (NSValue *value in array) {
        CGPoint point = value.pointValue;
        sumOfDistances += sqrtf(pow(point.x - avgX, 2.0f) + pow(point.y - avgY, 2.0f));
    }
    return sumOfDistances;
}

+(float)meanOfSquareDistancesPointArray:(NSArray *)array{//Array of NSValue points
    return [IMCUtils sumOfSquareDistancesPointArray:array]/array.count;
}

+(float)wardForArray1:(NSArray *)array1 array2:(NSArray *)array2{
    if(array1.count == 0 || array2.count == 0)return .0f;
    float ss1 = [IMCUtils sumOfSquareDistancesPointArray:array1];
    float ss2 = [IMCUtils sumOfSquareDistancesPointArray:array2];
    float ss12 = [IMCUtils sumOfSquareDistancesPointArray:[array1 arrayByAddingObjectsFromArray:array2]];
    
    return ss12 - (ss1 + ss2);
}

+(float)minimalIncreaseOfVarianceForArray1:(NSArray *)array1 array2:(NSArray *)array2{
    if(array1.count == 0 || array2.count == 0)return .0f;
    float ward = [IMCUtils wardForArray1:array1 array2:array2];
    return ward/(array1.count + array2.count);
}

//+(float)nomeacuerdolocambiare:(NSArray *)array1 array2:(NSArray *)array2{
//    if(array1.count == 0 || array2.count == 0)return .0f;
//    float ss1 = [IMCUtils meanOfSquareDistancesPointArray:array1];
//    float ss2 = [IMCUtils meanOfSquareDistancesPointArray:array2];
//    float ss12 = [IMCUtils meanOfSquareDistancesPointArray:[array1 arrayByAddingObjectsFromArray:array2]];
//
//    return ss12 - (ss1 + ss2);
//}
//
//+(float)nomeacuerdolocambiareWeighter:(NSArray *)array1 array2:(NSArray *)array2{
//    if(array1.count == 0 || array2.count == 0)return .0f;
//    float ward = [IMCUtils nomeacuerdolocambiare:array1 array2:array2];
//    return ward/(array1.count + array2.count);
//}

+ (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
//    NSAlert *alert = [NSAlert alertWithMessageText: prompt
//                                     defaultButton:@"OK"
//                                   alternateButton:@"Cancel"
//                                       otherButton:nil
//                         informativeTextWithFormat:@""];
    
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = prompt;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {//NSAlertDefaultReturn
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertSecondButtonReturn) {//NSAlertAlternateReturn
        return nil;
    } else {
        return nil;
    }
}

+ (NSInteger)inputOptions:(NSArray *)values prompt:(NSString *)prompt{
    //    NSAlert *alert = [NSAlert alertWithMessageText: prompt
    //                                     defaultButton:@"OK"
    //                                   alternateButton:@"Cancel"
    //                                       otherButton:nil
    //                         informativeTextWithFormat:@""];
    
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = prompt;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSPopUpButton *input = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    for (NSString *value in values) {
        [input addItemWithTitle:value];
    }

    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {//NSAlertDefaultReturn
        [input validateEditing];
        return [input indexOfSelectedItem];
    } else if (button == NSAlertSecondButtonReturn) {//NSAlertAlternateReturn
        return NSNotFound;
    } else {
        return NSNotFound;
    }
}

+ (NSIndexSet *)inputTable:(NSArray *)values prompt:(NSString *)prompt{
    
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = prompt;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    float heightButton = 20;
    
    NSScrollView *input = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 300, 300)];
    float height = heightButton * values.count;
    NSView *inner = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, height)];
    
    NSMutableArray *buttons = @[].mutableCopy;
    for (NSString *val in values) {
        NSButton *but = [[NSButton alloc]initWithFrame:NSMakeRect(0, height - ([values indexOfObject:val] + 1) * heightButton, 300, heightButton)];
        [but setButtonType:NSSwitchButton];
        but.title = val;
        but.state = NSOnState;
        [but setTag:[values indexOfObject:val]];
        [inner addSubview:but];
        [buttons addObject:but];
    }
    input.documentView = inner;
    
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertFirstButtonReturn) {//NSAlertDefaultReturn
        NSMutableIndexSet *is = [[NSMutableIndexSet alloc]init];
        for (NSButton *but in buttons)
            if(but.state == NSOnState)
                [is addIndex:but.tag];
        return is;
    } else if (button == NSAlertSecondButtonReturn) {//NSAlertAlternateReturn
        return nil;
    } else {
        return nil;
    }
}

@end
