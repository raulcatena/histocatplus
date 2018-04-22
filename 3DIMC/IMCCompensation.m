//
//  IMCCompensation.m
//  3DIMC
//
//  Created by Raul Catena on 9/10/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMCCompensation.h"
#import "IMCLoader.h"

@interface IMCCompensation ()
@property (nonatomic, strong) IMCLoader *lodaer;
@property (nonatomic, strong) NSArray<NSMutableArray *> *matrix;
@end

@implementation IMCCompensation

-(void)fetchMatrix{
    NSMutableArray *build = @[].mutableCopy;
    NSArray *lines = [self.lodaer.compMatrix componentsSeparatedByString:@"\r"];
    for (NSString *line in lines) {
        NSMutableArray *comps = [[line componentsSeparatedByString:@"\t"]mutableCopy];
        [build addObject:comps];
    }
    self.matrix = build;
}

-(instancetype)initWithDataCoordinator:(IMCLoader *)coordinator{
    self = [self initWithWindowNibName:NSStringFromClass([IMCCompensation class]) owner:self];
    if(self){
        self.lodaer = coordinator;
        assert(self.lodaer);
        [self fetchMatrix];
    }
    return self;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.matrix.count - 1;
}
-(void)prepareColumns{
    while (self.tableView.tableColumns.count > 0) {
        NSTableColumn *col = [[self.tableView tableColumns]firstObject];
        [self.tableView removeTableColumn:col];
    }
    NSArray *headers = self.matrix.firstObject;
    for (NSString *str in headers) {
        NSTableColumn* aColumn = [[NSTableColumn alloc] initWithIdentifier:str];
        aColumn.title = str;
        aColumn.width = [headers indexOfObject:str] == 0? 50.0f : 40.0f;
        [self.tableView addTableColumn:aColumn];
    }
}
- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self prepareColumns];
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSInteger indexCol = [tableView.tableColumns indexOfObject:tableColumn];
    return self.matrix[row + 1][indexCol];
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSInteger indexCol = [tableView.tableColumns indexOfObject:tableColumn];
    [self.matrix[row + 1] replaceObjectAtIndex:indexCol withObject:object];
}
-(void)saveMatrix:(id)sender{
    NSMutableString *newMatrix = @"".mutableCopy;
    for (NSArray *line in self.matrix) {
        [newMatrix appendString:[line componentsJoinedByString:@"\t"]];
        if(line != self.matrix.lastObject)
            [newMatrix appendString:@"\r"];
    }
    self.lodaer.jsonDescription[COMP_MATRIX] = [NSString stringWithString:newMatrix];
}
-(void)revertFactory:(id)sender{
    NSInteger sure = [General runAlertModalAreYouSureWithMessage:@"Are you sure"];
    if(sure == NSAlertFirstButtonReturn){
        [self.lodaer.jsonDescription removeObjectForKey:COMP_MATRIX];
    }
    [self fetchMatrix];
    [self prepareColumns];
    [self.tableView reloadData];
}

@end
