//
//  IMCMiniRConsole.m
//  3DIMC
//
//  Created by Raul Catena on 3/15/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCMiniRConsole.h"

@interface IMCMiniRConsole ()

@end

@implementation IMCMiniRConsole

-(instancetype)init{
    return [self initWithWindowNibName:NSStringFromClass([IMCMiniRConsole class]) owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.rScript.font = [NSFont fontWithName:@"Courier" size:14.f];
    self.rScript.automaticQuoteSubstitutionEnabled = NO;
}
-(void)textDidChange:(NSNotification *)notification{
//    NSString *str = [self.rScript.string stringByReplacingOccurrencesOfString:@"‘" withString:@"'"];
//    str = [str stringByReplacingOccurrencesOfString:@"“" withString:@"\""];
//    str = [str stringByReplacingOccurrencesOfString:@"”" withString:@"\""];
//    self.rScript.string = str;
}

@end
