//
//  IMCDrawableImageView.m
//  IMCReader
//
//  Created by Raul Catena on 10/7/15.
//  Copyright © 2015 CatApps. All rights reserved.
//

#import "IMCImageView.h"
#import "IMCImageStack.h"
#import "IMCScale.h"

@interface IMCImageView(){
    NSPoint start;
}
@property (nonatomic, strong) IMCScale *scaleBar;
@end

@implementation IMCImageView


- (float)photoReduction {
    NSSize size = [[self image] size];
    NSRect iFrame = [self bounds];
    if (NSWidth(iFrame) > size.width && NSHeight(iFrame) > size.height) return 1.0; // it fits
    else {
        // one leg of the photo doesn't fit - the smallest ratio rules
        double xRatio = NSWidth(iFrame)/size.width;
        double yRatio = NSHeight(iFrame)/size.height;
        return MIN (xRatio, yRatio);
    }
}

- (NSRect)photoRectInImageView {
    NSSize size = [[self image] size];
    NSRect iBounds = [self bounds];
    float reduction = [self photoReduction];
    NSRect photoRect;
    
    photoRect.size.width = floor(size.width * reduction + 0.5);
    photoRect.size.height = floor(size.height * reduction + 0.5);
    photoRect.origin.x = floor((iBounds.size.width - photoRect.size.width)/2.0 + 0.5);
    photoRect.origin.y = floor((iBounds.size.height - photoRect.size.height)/2.0 + 0.5);
    return (photoRect);
}

-(NSPoint)originOfContainedImage{
    NSPoint point;
    float proportion = self.image.size.width / self.image.size.height;
    //// A and B height and width of container, a and b height and width of containerm c height of label, p proportion
    ////c = a + (A - a) / 2  where a = b/p and B = b. Then a = B/p. c = B/p + (A - B/p)/2
    ////Same for d (x axis) then A = a and b = p * a. Hence d = (B - p * a)/2
    NSSize size = self.bounds.size;
    point.x = MAX(0, (size.width - proportion * size.height) / 2);
    point.y = MAX(0, (size.height - size.width/proportion)/2);
    return point;
}

-(NSPoint)topOriginOfContainedImage{
    NSPoint point;
    float proportion = self.image.size.width / self.image.size.height;
    NSSize size = self.bounds.size;
    point.x = MAX(0, (size.width - proportion * size.height) / 2);
    point.y = MIN(size.height, size.width/proportion + (size.height - size.width/proportion)/2);
    
    return point;
}
-(NSPoint)yFlippedtopOriginOfContainedImage{
    NSPoint point;
    float proportion = self.image.size.width / self.image.size.height;
    NSSize size = self.bounds.size;
    point.x = MAX(0, (size.width - proportion * size.height) / 2);
    point.y = MIN(size.height, size.width/proportion + (size.height - size.width/proportion)/2);
    point.y = self.bounds.size.height - point.y;
    
    return point;
}

-(NSSize)sizeOfInscribedImgFrame{
    NSPoint or = [self originOfContainedImage];
    return NSMakeSize(self.bounds.size.width - 2 * or.x, self.bounds.size.height - 2 * or.y);
}

-(NSRect)rectOfInscribedImgFrame{
    NSPoint or = [self originOfContainedImage];
    NSSize size = [self sizeOfInscribedImgFrame];
    CGRect rect;
    rect.size = size;
    rect.origin = or;
    return rect;
}

-(void)setStacks:(NSArray<IMCImageStack *> *)stacks{
    _stacks = stacks;
    [self needsToDrawRect:self.bounds];
}

-(void)drawROIsInPanorama{
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSetLineWidth(context, 2.0);
    [[NSColor whiteColor] setStroke];
    
    float coef = [self.stacks.firstObject.parent.jsonDictionary[JSON_DICT_CONT_PANORAMA_COEF]floatValue];
    CGSize sizePan = NSMakeSize([self.stacks.firstObject.parent.jsonDictionary[JSON_DICT_CONT_PANORAMA_W]floatValue],
                                [self.stacks.firstObject.parent.jsonDictionary[JSON_DICT_CONT_PANORAMA_H]floatValue]);
    sizePan.width *= coef;
    sizePan.height *= coef;
    /*
    NSLog(@"Coef is %f", coef);
    NSLog(@"Size image %@", NSStringFromSize(self.image.size));
    NSLog(@"Size pan %@", NSStringFromSize(sizePan));
    NSLog(@"Size iv are %@", NSStringFromSize(self.bounds.size));*/
    
    CGPoint origin = [self yFlippedtopOriginOfContainedImage];
    CGRect inscribedRect = [self rectOfInscribedImgFrame];
    
    CGPoint props = NSMakePoint(inscribedRect.size.width/sizePan.width,
                                inscribedRect.size.height/sizePan.height);
    
    /*
    NSLog(@"Props are %@", NSStringFromPoint(props));
    NSLog(@"Or are %@", NSStringFromPoint(origin));
     */
    
    
    for (IMCImageStack *stack in self.stacks) {
        NSRect rect = NSRectFromString(stack.jsonDictionary[JSON_DICT_IMAGE_RECT_IN_PAN]);
        //NSLog(@"Rect from FDGM %@", NSStringFromRect(rect));
        rect.origin.x *= props.x;
        rect.origin.x += origin.x;
        rect.size.width *= props.x;
        rect.size.height *= props.y;
        rect.origin.y = self.bounds.size.height - rect.size.height - (rect.origin.y * props.y);
        rect.origin.y -= origin.y;
        
        //NSLog(@"B %@", NSStringFromRect(rect));
        CGPoint addLines[] =
        {
            CGPointMake(rect.origin.x, rect.origin.y),
            CGPointMake(rect.origin.x + rect.size.width, rect.origin.y),
            CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height),
            CGPointMake(rect.origin.x, rect.origin.y + rect.size.height),
            CGPointMake(rect.origin.x, rect.origin.y),
        };
        // Bulk call to add lines to the current path.
        // Equivalent to MoveToPoint(points[0]); for(i=1; i<count; ++i) AddLineToPoint(points[i]);
        CGContextAddLines(context, addLines, sizeof(addLines)/sizeof(addLines[0]));
        CGContextStrokePath(context);
        
        [stack.itemName drawInRect:CGRectMake(rect.origin.x + 5, rect.origin.y, rect.size.width, 20) withAttributes:@{
                                                                                                                  NSForegroundColorAttributeName: [NSColor whiteColor]}];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [super drawRect:dirtyRect];
    [self drawROI];
    if(self.stacks.count > 0)
        [self drawROIsInPanorama];
}

-(BOOL)becomeFirstResponder{
    return YES;
}

-(void)rightMouseDown:(NSEvent *)theEvent{
    _selectedArea = CGRectZero;
    NSPoint event_location = [theEvent locationInWindow];
    start = [self convertPoint:event_location fromView:nil];//Important to pass nil
}

-(void)rightMouseDragged:(NSEvent *)theEvent{
    NSPoint endInWindow = [theEvent locationInWindow];
    NSPoint end = [self convertPoint:endInWindow fromView:nil];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    //Invert if necessar
    if(start.y < end.y){
    
    }
    
    _selectedArea = CGRectMake(start.x/width, start.y/height, (end.x - start.x)/width, (end.y - start.y)/height);
    [self setNeedsDisplay:YES];
}
                     
-(void)rightMouseUp:(NSEvent *)theEvent{
    
    //[self selectedRectProportions];
}

-(void)drawROI{
    if(_selectedArea.size.width < .01f)return;
    
    CGContextRef context = [[NSGraphicsContext currentContext] CGContext];
    
    CGContextSetLineWidth(context, 2.0);
    [[NSColor whiteColor] setStroke];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGPoint addLines[] =
    {
        CGPointMake(_selectedArea.origin.x * width, _selectedArea.origin.y * height),
        CGPointMake((_selectedArea.origin.x + _selectedArea.size.width) * width, _selectedArea.origin.y * height),
        CGPointMake((_selectedArea.origin.x + _selectedArea.size.width) * width , (_selectedArea.origin.y + _selectedArea.size.height) * height),
        CGPointMake(_selectedArea.origin.x * width, (_selectedArea.origin.y + _selectedArea.size.height) * height),
        CGPointMake(_selectedArea.origin.x * width, _selectedArea.origin.y * height),
    };
    // Bulk call to add lines to the current path.
    // Equivalent to MoveToPoint(points[0]); for(i=1; i<count; ++i) AddLineToPoint(points[i]);
    CGContextAddLines(context, addLines, sizeof(addLines)/sizeof(addLines[0]));
    CGContextStrokePath(context);
}
#pragma mark addons to view ports


-(void)addScaleWithScaleFactor:(float)factor color:(NSColor *)color fontSize:(float)fontSize widthPhoto:(NSInteger)width stepForced:(NSInteger)forceStep onlyBorder:(BOOL)onlyBorder static:(BOOL)staticBar{
    
    [self.scaleBar removeFromSuperview];
    
    if(width < 0)return;
    
    NSPoint or = [self topOriginOfContainedImage];
    CGRect rect = CGRectMake(0,
                           self.bounds.size.height - or.y,
                           self.bounds.size.width,
                           MAX(100, self.bounds.size.width/5.0f));
    
    if(staticBar == YES)
        rect.origin.x -=  self.bounds.size.width/5.0f;
    
    self.scaleBar = [[IMCScale alloc]initWithFrame:rect
                                    andScaleFactor:factor
                                          andColor:color
                                        widthPhoto:width
                                         atXOrigin:or.x
                                          fontSize:fontSize
                                        stepForced:forceStep
                                        onlyBorder:onlyBorder];
    
    if(staticBar == YES)[self.superview.superview addSubview:self.scaleBar];
    else [self addSubview:self.scaleBar];
    
}

#define GAP 5.0f
-(void)setLabels:(NSArray *)titles withColors:(NSArray *)colors backGround:(NSColor *)backgroundColor fontSize:(CGFloat)fontSize vAlign:(BOOL)vAlign static:(BOOL)staticLabels{
    
    [self removeLabels];

    NSPoint or = [self topOriginOfContainedImage];
    
    float cumulative = .0f;
    
    for (int i = 0; i < titles.count; i++) {
        
        NSColor * color = i < colors.count ? [colors objectAtIndex:i] : nil;
        NSString *channelName = [titles objectAtIndex:i];
        
        NSTextField *field = [[NSTextField alloc]initWithFrame:CGRectZero];
        
        field.stringValue = channelName;
        field.textColor = color?color:[NSColor purpleColor];
        field.backgroundColor = backgroundColor;
        field.bordered = NO;
        [field setFont:[NSFont systemFontOfSize:fontSize]];
        float width = field.attributedStringValue.size.width + 10;
        float jeit = field.attributedStringValue.size.height + 10;
        
        
        float passX = cumulative;
        int passY = 1;
        if(vAlign == YES){
            passX = 0.0f;
            passY = i + 1;
        }
        
        if(staticLabels == YES){
            or.x = [self photoRectInImageView].origin.x;
            or.y = jeit + GAP + GAP;
        }
        
        
        float yPos = or.y - jeit * passY;
        if(vAlign && staticLabels)yPos = jeit * passY;
        field.frame = CGRectMake(or.x + passX + GAP,
                                 yPos,
                                 width,
                                 jeit);
        
        
        cumulative = cumulative + width;
        [field setNeedsDisplay:YES];
        if(staticLabels == YES)[self.superview.superview addSubview:field];
        else [self addSubview:field];
    }
}

-(void)removeScale{
    [self.scaleBar removeFromSuperview];
}

-(void)removeLabels{
    for(NSView *aV in self.subviews.copy){
        if([aV isMemberOfClass:[NSTextField class]])[aV removeFromSuperview];
    }
    for(NSView *aV in self.superview.superview.subviews.copy){
        if([aV isMemberOfClass:[NSTextField class]])[aV removeFromSuperview];
    }
}

@end
