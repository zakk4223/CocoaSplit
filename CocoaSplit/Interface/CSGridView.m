//
//  CSGridView.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSGridView.h"

@implementation CSGridView

-(void)layout
{
    NSInteger subViewCnt = self.subviews.count;
    float countsq = sqrt(subViewCnt);
    NSInteger nextint = (NSInteger)ceil(countsq);
    NSInteger columns =  nextint;
    NSInteger rows = ceil(subViewCnt/(float)columns);
    
    CGFloat boxWidth = self.frame.size.width/columns;
    CGFloat boxHeight = self.frame.size.height/rows;
    
    NSInteger viewIdx = 0;
    
    NSPoint curPoint = NSMakePoint(0.0, NSMaxY(self.bounds)-boxHeight);
    
    for (int r = 0; r < rows; r++)
    {
        for (int c = 0; c < columns; c++)
        {
            
            if (viewIdx < self.subviews.count)
            {
                NSView *subView = [self.subviews objectAtIndex:viewIdx];
                
                NSRect viewFrame = NSIntegralRect(NSMakeRect(curPoint.x, curPoint.y, boxWidth, boxHeight));
                [subView setFrame:viewFrame];
                
                curPoint.x += boxWidth;
                viewIdx++;
                
            }
        }
        curPoint.y -= boxHeight;
        curPoint.x = 0;
    }
}

@end
