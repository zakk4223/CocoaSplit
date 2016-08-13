//
//  CSNobarSlider.m
//  CocoaSplit
//
//  Created by Zakk on 8/13/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSNobarSlider.h"

@implementation CSNobarSlider

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

+(Class)cellClass
{

    return [CSNobarSliderCell class];
}


- (void)awakeFromNib {
    [super awakeFromNib];
    
    if( ![self.cell isKindOfClass:[CSNobarSlider class]] ) {
        CSNobarSliderCell *cell = [[CSNobarSliderCell alloc] init];
        [self setCell:cell];
    }
}

@end
