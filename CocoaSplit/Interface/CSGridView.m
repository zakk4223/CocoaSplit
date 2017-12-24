//
//  CSGridView.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//

#import "CSGridView.h"



@implementation CSGridView

-(void)drawRect:(NSRect)dirtyRect
{
    if (self.backgroundColor)
    {
        [self.backgroundColor setFill];
        NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    }
    
    [super drawRect:dirtyRect];
}


-(void)layout
{
    [super layout];
    NSInteger subViewCnt = self.subviews.count;
    float countsq = sqrt(subViewCnt);
    NSInteger nextint = (NSInteger)ceil(countsq);
    NSInteger columns =  nextint;
    if (self.minimumColumns && columns < self.minimumColumns)
    {
        columns = self.minimumColumns;
    }
    NSInteger rows = ceil(subViewCnt/(float)columns);
    
    if (self.minimumRows && rows < self.minimumRows)
    {
        rows = self.minimumRows;
    }

    CGFloat totalWidth = self.frame.size.width - ((columns) * self.columnGap);
    CGFloat totalHeight = self.frame.size.height - ((rows) * self.rowGap);;
    
    CGFloat boxWidth = totalWidth/columns;
    CGFloat boxHeight = totalHeight/rows;
    
    /*
    if (boxHeight > boxWidth)
    {
        boxHeight = boxWidth;
    } else if (boxWidth > boxHeight) {
        boxWidth = boxHeight;
    }
     */
    
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
                [subView layout];
                curPoint.x += boxWidth+self.columnGap;
                viewIdx++;
                
            }
        }
        curPoint.y -= (boxHeight+self.rowGap);
        curPoint.x = 0;
    }
}

@end
