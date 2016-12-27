//
//  CSCaptureBase+InputFrameTick.m
//  CocoaSplit
//
//  Created by Zakk on 12/27/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSCaptureBase+InputFrameTick.h"

@implementation CSCaptureBase (InputFrameTick)
@dynamic tickInput;



-(void)frameTickFromInput:(InputSource *)input
{
    
    if (self.tickInput && (input == self.tickInput))
    {
        
        [self frameTick];
    }
}
@end
