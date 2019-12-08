//
//  CSLayoutButton.m
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//

#import "CSLayoutButton.h"
#import "CSLayoutCollectionItem.h"
#import "CSPreviewGLLayer.h"

@implementation CSLayoutButton





-(BOOL)wantsUpdateLayer
{
    return YES;
}

-(void)updateLayer
{
    CGColorRef backgroundColor;
    CGFloat useAlpha = 1.0f;
    
    /*
    if (self.cell.isHighlighted)
    {
        useAlpha = 0.3f;
    }
     */
    SourceLayout *myLayout = self.viewController.representedObject;
    if (myLayout.in_staging && myLayout.in_live)
    {
        backgroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 0.0f, useAlpha);
    } else if (myLayout.in_staging) {
        backgroundColor = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, useAlpha);
    } else if (myLayout.in_live) {
        backgroundColor = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, useAlpha);
    } else {
        backgroundColor = CGColorCreateGenericRGB(0.353f, 0.534f, 0.434, useAlpha);
    }
    self.layer.backgroundColor = backgroundColor;
    self.layer.cornerRadius = 5.0f;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSColor *redColor = [NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    NSColor *greenColor = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
    
    NSRect mybounds = self.bounds;
    
    SourceLayout *myLayout = self.viewController.representedObject;
    if (myLayout.in_staging)
    {
        [greenColor set];
        
        NSRect fillBox = mybounds;
        
        //fillBox.size.width = fillBox.size.width/2;
        
        NSRectFillUsingOperation(fillBox, NSCompositingOperationSourceOver);
    }
    
    if (myLayout.in_live)
    {
        [redColor set];
        
        NSRect fillBox = mybounds;
        
        fillBox.size.width = fillBox.size.width/2;
        fillBox.origin.x = fillBox.origin.x + fillBox.size.width;
        
        NSRectFillUsingOperation(fillBox, NSCompositingOperationSourceOver);
    }

    
    
    // Drawing code here.
}


/*
-(void)mouseDown:(NSEvent *)theEvent
{
    [self highlight:YES];
    [self.nextResponder mouseDown:theEvent];
    _savedMouseDown = theEvent;

    return;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [self highlight:NO];
    [self.nextResponder mouseDown:_savedMouseDown];
    [self.nextResponder mouseDragged:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    [self performClick:self];
    [self.nextResponder mouseUp:theEvent];
}
*/


-(void)rightMouseDown:(NSEvent *)theEvent
{
    
    [self.viewController showLayoutMenu:theEvent];
}


-(void)dealloc
{
    [self.viewController removeObserver:self forKeyPath:@"representedObject.in_live"];
    [self.viewController removeObserver:self forKeyPath:@"representedObject.in_staging"];

    
}
@end
