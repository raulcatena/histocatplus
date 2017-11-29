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
#import "IMCTiledScrollView.h"

@interface IMCPositions ()
@property (nonatomic, strong) IMCLoader *loader;
@property (nonatomic, strong) IMCMtkView *metalView;
@property (nonatomic, strong) IMCTiledScrollView *scrollView;
@end

@implementation IMCPositions

-(void)addProfile:(id)sender{
    NSMutableDictionary *dict = @{METAL_BASE_MATRIX: self.metalView.baseModelMatrix.stringRepresentation,
                                  METAL_ROT_MATRIX: self.metalView.rotationMatrix.stringRepresentation,
                                  THREE_D_ROI: NSStringFromRect([self.delegate rectToRender]),
                                  METAL_LEFT_X_OFFSET: @(self.metalView.leftXOffset),
                                  METAL_RIGHT_X_OFFSET:@(self.metalView.rightXOffset),
                                  METAL_UPPER_Y_OFFSET:@(self.metalView.upperYOffset),
                                  METAL_LOWER_Y_OFFSET:@(self.metalView.lowerYOffset),
                                  METAL_NEAR_Z_OFFSET:@(self.metalView.nearZOffset),
                                  METAL_FAR_Z_OFFSET: @(self.metalView.farZOffset)}.mutableCopy;
    
    
    NSString *string;
    do{
        string = [IMCUtils input:@"Give a name to this profile" defaultValue:@"New position profile"];
    }
    while ([self.loader.positions.allKeys containsObject:string]);
    if(string)
        [self.loader.positions setObject:dict forKey:string];
    [self updateProfiles];
    [self.tableView reloadData];
    [self.positionsSelector selectItemAtIndex:0];
}

-(void)removeProfile:(id)sender{
    NSInteger sure = [General runAlertModalAreYouSure];
    if(sure == NSAlertFirstButtonReturn){
        NSInteger prev = self.positionsSelector.indexOfSelectedItem;
        if(prev > 0)
             [self.loader.positions removeObjectForKey:self.positionsSelector.titleOfSelectedItem];
        [self updateProfiles];
        [self.tableView reloadData];
    }
}
-(void)setPositionProfile:(id)sender{
    NSInteger prev = self.positionsSelector.indexOfSelectedItem;
    if(prev > 0){
        NSMutableDictionary *dict = self.loader.positions[[self.positionsSelector titleOfSelectedItem]];
        
        [self.metalView.baseModelMatrix setMatrixFromStringRepresentation:dict[METAL_BASE_MATRIX]];
        [self.metalView.rotationMatrix setMatrixFromStringRepresentation:dict[METAL_ROT_MATRIX]];
        [self.metalView applyRotationWithInternalState];
        [self.scrollView.imageView setSelectedArea:NSRectFromString(dict[THREE_D_ROI])];
        
        self.metalView.leftXOffset = [dict[METAL_LEFT_X_OFFSET]floatValue];
        self.metalView.rightXOffset = [dict[METAL_RIGHT_X_OFFSET]floatValue];
        self.metalView.upperYOffset = [dict[METAL_UPPER_Y_OFFSET]floatValue];
        self.metalView.lowerYOffset = [dict[METAL_LOWER_Y_OFFSET]floatValue];
        self.metalView.nearZOffset = [dict[METAL_NEAR_Z_OFFSET]floatValue];
        self.metalView.farZOffset = [dict[METAL_FAR_Z_OFFSET]floatValue];
    }
}
-(void)refreshList:(id)sender{
    [self updateProfiles];
    [self.tableView reloadData];
}

-(void)updateProfiles{
    NSDictionary *dict = [self.loader positions];
    
    NSInteger prev = self.positionsSelector.indexOfSelectedItem;
    [self.positionsSelector removeAllItems];
    [self.positionsSelector addItemWithTitle:@"Current"];
    for(NSDictionary *title in dict.allKeys){
        [self.positionsSelector addItemWithTitle:@"foo"];
        self.positionsSelector.lastItem.title = title.copy;
    }
    [self.positionsSelector selectItemAtIndex:MIN(prev, dict.allKeys.count)];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.title = [@"Positional manager " stringByAppendingString:self.loader.filePath.lastPathComponent];
    [self updateProfiles];
}

-(instancetype)initWithLoader:(IMCLoader *)loader andView:(IMCMtkView *)view andSV:(IMCTiledScrollView *)scrollView{
    self = [self initWithWindowNibName:NSStringFromClass([self class]) owner:self];
    if(self){
        self.loader = loader;
        self.metalView = view;
        self.scrollView = scrollView;
    }
    return self;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    //Base Model Matrix from MetalView
    //Rotation Matrix from MetalView
    //Selected ROI
    return 9;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *str = @"";
    NSDictionary *dict;
    if(self.positionsSelector.indexOfSelectedItem > 0){
        dict = self.loader.positions[[self.positionsSelector titleOfSelectedItem]];
    }else{
        dict = @{METAL_BASE_MATRIX: self.metalView.baseModelMatrix.stringRepresentation,
                 METAL_ROT_MATRIX: self.metalView.rotationMatrix.stringRepresentation,
                 THREE_D_ROI: NSStringFromRect([self.delegate rectToRender]),
                 METAL_LEFT_X_OFFSET: @(self.metalView.leftXOffset),
                 METAL_RIGHT_X_OFFSET:@(self.metalView.rightXOffset),
                 METAL_UPPER_Y_OFFSET:@(self.metalView.upperYOffset),
                 METAL_LOWER_Y_OFFSET:@(self.metalView.lowerYOffset),
                 METAL_NEAR_Z_OFFSET:@(self.metalView.nearZOffset),
                 METAL_FAR_Z_OFFSET: @(self.metalView.farZOffset)};
    }
    NSArray * titlesRows3DSetts = @[@"Base Model Matrix", @"Rotation Matrix", @"ROI Rectangle", @"Left X Offset", @"Right X Offset", @"Lower Y Offset", @"Upper Y Offset", @"Near Z Offset", @"Far Z Offset"];
    NSArray * keysRows3DSetts = @[METAL_BASE_MATRIX, METAL_ROT_MATRIX, THREE_D_ROI, METAL_LEFT_X_OFFSET, METAL_RIGHT_X_OFFSET, METAL_UPPER_Y_OFFSET, METAL_LOWER_Y_OFFSET, METAL_NEAR_Z_OFFSET, METAL_FAR_Z_OFFSET];
    
    if([tableColumn.identifier isEqualToString:@"Title"])
        str = titlesRows3DSetts[row];
    else
        str = dict[keysRows3DSetts[row]];

    return str;
}
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

}

@end
