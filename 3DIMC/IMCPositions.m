//
//  IMCPositions.m
//  3DIMC
//
//  Created by Raul Catena on 11/29/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCPositions.h"
#import "IMCLoader.h"
#import "IMCMtkView.h"

@interface IMCPositions ()
@property (nonatomic, strong) IMCLoader *loader;
@property (nonatomic, weak) IMCMtkView *metalView;
@end

@implementation IMCPositions

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.title = [@"Positional manager " stringByAppendingString:self.loader.filePath.lastPathComponent];
}

-(instancetype)initWithLoader:(IMCLoader *)loader andView:(IMCMtkView *)view{
    self = [self initWithWindowNibName:NSStringFromClass([self class]) owner:self];
    if(self){
        self.loader = loader;
        self.metalView = view;
    }
    return self;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    //Rect is 4
    //zoom
    //X, Y
    //rotation X, Y
    return 9;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    return @"AAA";
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

}

@end
