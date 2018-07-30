//
//  IMC3dMasking.m
//  3DIMC
//
//  Created by Raul Catena on 9/21/17.
//  Copyright © 2017 CatApps. All rights reserved.
//

#import "IMC3dMasking.h"
#import "IMCPixelClassification.h"
#import "IMCImageGenerator.h"
#import "IMCVoxelMaskRenderer.h"
#import "NSImage+OpenCV.h"


UInt8 ** buffAll;
@interface IMC3dMasking (){
//    UInt8 ** buffAll;
}
@property (nonatomic, strong) NSArray * masks;
@property (nonatomic, strong) IMCVoxelMaskRenderer * renderer;
@end

@implementation IMC3dMasking

-(instancetype)init{
    return [self initWithWindowNibName:NSStringFromClass([IMC3dMasking class])];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//TODO
        [[NSApplication sharedApplication] runModalForWindow:self.window];
        
    });
    self.masks = [self.delegate masks];
    self.renderer = [[IMCVoxelMaskRenderer alloc]init];
    self.metalView.delegate = self.renderer;
}
- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [self.delegate masks].count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    IMCPixelClassification * mask = self.masks[row];
    return tableColumn.identifier?mask.itemName:mask.itemSubName;
}

-(void)refresh{
    NSInteger maxW = 0, maxH = 0;
    for (IMCPixelClassification *stk in self.masks.copy) {
        if(stk.imageStack.width > maxW)maxW = stk.imageStack.width;
        if(stk.imageStack.height > maxH)maxH = stk.imageStack.height;
    }
//    for (IMCComputationOnMask *comp in self.parent.inScopeComputations.copy) {
//        if(comp.mask.imageStack.width > maxW)maxW = comp.mask.imageStack.width;
//        if(comp.mask.imageStack.height > maxH)maxH = comp.mask.imageStack.height;
//    }
    
    if(maxW == 0 && maxH == 0)return;
    
    float factor = 1.5f;
    
    NSMutableArray *sub = @[].mutableCopy;
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger ind, BOOL *stop){
        [sub addObject:[self.masks objectAtIndex:ind]];
    }];
    
    //3D alignment
    NSImage *image = [IMCImageGenerator imageForImageStacks:nil
                                                    indexes:nil
                                           withColoringType:0
                                               customColors:@[]
                                          minNumberOfColors:0
                                                      width:maxW * factor
                                                     height:maxH * factor
                                             withTransforms:YES
                                                      blend:kCGBlendModeScreen
                                                   andMasks:sub
                                            andComputations:nil
                                                 maskOption:MASK_NO_BORDERS
                                                   maskType:MASK_NUC
                                            maskSingleColor:[NSColor whiteColor]
                                            isAlignmentPair:NO
                                                brightField:NO];
    
    

    
    if(buffAll){
        for (NSInteger i = 0; i < self.masks.count; i++) {
            if(buffAll[i])
                free(buffAll[i]);
        }
        free(buffAll);
        buffAll = NULL;
    }
    buffAll = (UInt8 **)calloc(self.masks.count, sizeof(UInt8 *));
    
    NSInteger total  = maxW * factor * maxH * factor;
    
    [self.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger ind, BOOL *stop){
        
        NSImage *anIm = [IMCImageGenerator imageForImageStacks:nil indexes:nil withColoringType:0 customColors:@[] minNumberOfColors:0 width:maxW * factor height:maxH * factor withTransforms:YES blend:kCGBlendModeScreen andMasks:@[self.masks[ind]] andComputations:nil maskOption:MASK_NO_BORDERS maskType:MASK_NUC maskSingleColor:[NSColor whiteColor] isAlignmentPair:NO brightField:NO];
        UInt8 *buff = [IMCImageGenerator bufferForImageRef:anIm.CGImage];
        
        if(buff)
            for (NSInteger i = 0; i < total; i++)
                if(buff[i] != 0)
                    buff[i] = buff[i]/buff[i];
    
        buffAll[ind] = buff;
    }];
    
    self.scrollLeft.imageView.image = image;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    [self refresh];
}

#pragma mark 3D delegate


@end
