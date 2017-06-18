//
//  CATransaction+JSExtensions.m
//  CocoaSplit
//
//  Created by Zakk on 6/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CATransaction+JSExtensions.h"

@implementation CATransaction (JSExtensions)

+ (void)setCompletionBlockJS:(JSValue *)jsvalue
{
    [CATransaction setCompletionBlock:^{
        
        [jsvalue callWithArguments:nil];
    }];
}



@end
