//
//  CSLayoutButton.m
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutButton.h"

@implementation CSLayoutButton


-(void)awakeFromNib
{
    [super awakeFromNib];
    

    if (self.viewController)
    {
        [self.viewController addObserver:self forKeyPath:@"representedObject.in_live" options:NSKeyValueObservingOptionNew context:NULL];
        [self.viewController addObserver:self forKeyPath:@"representedObject.in_staging" options:NSKeyValueObservingOptionNew context:NULL];
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    [self setNeedsDisplay];
}


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


-(void)rightMouseDown:(NSEvent *)theEvent
{
    [self.viewController showLayoutMenu:theEvent];
}


@end
