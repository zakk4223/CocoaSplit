//
//  CSOutlineViewWithMenu.m
//  CocoaSplit
//
//  Created by Zakk on 4/14/18.
//

#import "CSOutlineViewWithMenu.h"
#import "CSOutlineViewMenuDelegate.h"


@implementation CSOutlineViewWithMenu

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(NSMenu *)menuForEvent:(NSEvent *)event
{
    if (!self.delegate)
    {
        return nil;
    }
    
    if ([self.delegate conformsToProtocol:@protocol(CSOutlineViewMenuDelegate)])
    {
        id <CSOutlineViewMenuDelegate> useDel = (id <CSOutlineViewMenuDelegate>)self.delegate;
        
        NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:nil];
        id item = [self itemAtRow:[self rowAtPoint:clickPoint]];
        return [useDel menuForItem:item];
    }
    return nil;
}
@end
