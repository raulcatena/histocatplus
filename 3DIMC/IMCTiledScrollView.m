//
//  IMCTiledScrollView.m
//  3DIMC
//
//  Created by Raul Catena on 1/23/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#import "IMCTiledScrollView.h"

@interface IMCTiledScrollView()
@property (nonatomic, strong) IMCScrollView *inScopeScroll;
@property (nonatomic, strong) NSMutableArray *scrollsPool;
@end

@implementation IMCTiledScrollView


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];    
}

#pragma mark Tiles

-(IMCScrollView *)getScrollFromPoolIndex:(NSInteger)index setRect:(CGRect)rect{
    if(!self.scrollsPool)self.scrollsPool = @[].mutableCopy;
    
    if(self.scrollsPool.count < index + 1){
        IMCScrollView *scr = [[IMCScrollView alloc]initWithFrame:rect];
        scr.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
        scr.allowsMagnification = self.scrollSubpanels;
        scr.maxMagnification = 30.0f;
        scr.minMagnification = 1.0f;
        
        scr.delegate = self;
        [self.scrollsPool addObject:scr];
        return scr;
    }
    IMCScrollView *scr = [self.scrollsPool objectAtIndex:index];
    scr.frame = rect;
    return scr;
    
}

-(void)assembleTiledWithImages:(NSArray <NSImage *>*)images{
    
    for (NSView *aV in self.imageView.subviews.copy) {
        [aV removeFromSuperview];
    }
    
    NSInteger rows = 1;
    NSInteger columns = images.count/rows;
    float widthTile = self.bounds.size.width/columns;
    float prop = images.firstObject.size.height/images.firstObject.size.width;
    float heightTile = widthTile * prop;
    
    float wrapperProp = self.bounds.size.width / self.bounds.size.height;
    
    while (heightTile * rows < self.bounds.size.height) {
        rows++;
        columns = ceil(images.count/(float)rows);
        widthTile = self.bounds.size.width/columns;
        heightTile = widthTile * prop;
    }
    
    if(wrapperProp > 1 && rows > columns){rows--;columns = ceil(images.count/(float)rows);}
    widthTile = self.bounds.size.width/columns;
    heightTile = widthTile * prop;
    
    //TODO refactor
    
    float yProp = rows * heightTile / self.contentSize.height;
    if(yProp > 1){
        widthTile /= yProp;
        heightTile /= yProp;
    }
    
    for (NSImage *im in images) {
        
        NSInteger idx = [images indexOfObject:im];
        NSView *v;
        IMCImageView *iv;
        
        if(self.scrollSubpanels){
            
            CGRect rect = CGRectMake(idx%columns * widthTile,
                                     self.contentSize.height - (idx/columns + 1) * heightTile,
                                     widthTile,
                                     heightTile);
            
            IMCScrollView *scr = [self getScrollFromPoolIndex:idx setRect:rect];
            scr.imageView.image = im;
            iv = scr.imageView;
            v = scr;
        }else{
            
            iv = [[IMCImageView alloc]initWithFrame:CGRectMake(idx%columns * widthTile,
                                                                           self.contentSize.height - (idx/columns + 1) * heightTile,
                                                                           widthTile,
                                                                           heightTile)];
            iv.image = im;
            iv.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
//            [self.documentView addSubview:iv];
            iv.image = im;
            v = iv;
        }
        [iv removeLabels];
        
        //Legends
        NSMutableArray *all = idx < self.channels.count? [self.channels[idx] mutableCopy] : @[].mutableCopy;
        NSMutableArray *allColors = idx < self.colorLegends.count? [self.colorLegends[idx] mutableCopy] : @[].mutableCopy;
        
        if(self.showImageNames){
            [all insertObject:idx < self.imageNames.count ? [self.imageNames objectAtIndex:idx] : @"" atIndex:0];
            [allColors insertObject:[NSColor whiteColor] atIndex:0];
        }
        if(self.showLegendChannels){
            //NSColor *color = self.colorLegends[MIN(self.colorLegends.count - 1,idx)];
            [iv setLabels:all withColors:allColors backGround:[NSColor colorWithWhite:0.1 alpha:0.2] fontSize:self.fontSizeLegends vAlign:YES static:iv.superview?YES:NO];
        }
        
        //Scale Bar
        
        [iv removeScale];
        
        if(self.showScaleBars)
            [iv addScaleWithScaleFactor:self.scaleCalibration color:self.legendColor fontSize:self.scaleFontSize widthPhoto:im.size.width stepForced:self.scaleStep onlyBorder:NO static:NO];
        
        [self.documentView addSubview:v];
    }
}

-(void)nilScopeScroll{
    self.inScopeScroll = nil;
}

-(void)scrolledWithScroll:(IMCScrollView *)scroll{
    if(self.syncronised == NO)return;
    if(!self.inScopeScroll){
        self.inScopeScroll = scroll;
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(nilScopeScroll) userInfo:nil repeats:NO];
    }
    if(scroll != self.inScopeScroll)return;

    NSPoint pos = scroll.documentVisibleRect.origin;
    for (IMCScrollView *aV in self.imageView.subviews) {
        if([aV isMemberOfClass:[IMCScrollView class]]){
            [aV.contentView scrollToPoint:pos];
            [aV setMagnification:scroll.magnification];
        }
    }
}

-(void)draggedThrough:(NSEvent *)event scroll:(IMCScrollView *)scroll{
    NSPoint pos = scroll.documentVisibleRect.origin;
    for (IMCScrollView *aV in self.imageView.subviews)
        if([aV isMemberOfClass:[IMCScrollView class]])
            [aV.contentView scrollToPoint:pos];
        
}

-(void)setScrollSubpanels:(BOOL)scrollSubpanels{
    _scrollSubpanels = scrollSubpanels;
    for (NSView *aV in self.imageView.subviews) {
        if([aV isMemberOfClass:[IMCScrollView class]]){
            IMCScrollView *scr = (IMCScrollView *)aV;
            scr.takingEvents = scrollSubpanels;
            scr.allowsMagnification = scrollSubpanels;
        }
    }
    self.allowsMagnification = !scrollSubpanels;
}

-(void)setSyncronised:(BOOL)syncronised{
    _syncronised = syncronised;
    for (IMCScrollView *aV in self.imageView.subviews) {
        if([aV isMemberOfClass:[IMCScrollView class]]){
            aV.delegate = syncronised == YES?self:nil;
        }
    }
}

-(void)clickedAtPoint:(NSPoint)point{

}

@end
