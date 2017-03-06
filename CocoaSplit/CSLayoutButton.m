//
//  CSLayoutButton.m
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutButton.h"
#import "CSLayoutCollectionItem.h"
#import "CSPreviewGLLayer.h"

@implementation CSLayoutButton





- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSColor *redColor = [NSColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.3];
    NSColor *greenColor = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.3];
    
    NSRect mybounds = self.bounds;
    
    SourceLayout *myLayout = self.viewController.representedObject;
    
    if (myLayout.in_staging)
    {
        [greenColor set];
        
        NSRect fillBox = mybounds;
        
        fillBox.size.width = fillBox.size.width/2;
        
        NSRectFillUsingOperation(fillBox, NSCompositeSourceOver);
    }
    
    if (myLayout.in_live)
    {
        [redColor set];
        
        NSRect fillBox = mybounds;
        
        fillBox.size.width = fillBox.size.width/2;
        fillBox.origin.x = fillBox.origin.x + fillBox.size.width;
        
        NSRectFillUsingOperation(fillBox, NSCompositeSourceOver);
    }

    
    
    // Drawing code here.
}


-(void)mouseDown:(NSEvent *)theEvent
{
    [self highlight:YES];
    //[self.nextResponder mouseDown:theEvent];'
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
