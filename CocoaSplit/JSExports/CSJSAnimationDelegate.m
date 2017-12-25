//
//  CSJSAnimationDelegate.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSJSAnimationDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation CSJSAnimationDelegate

-(instancetype)initWithJSAnimation:(JSValue *)jsAnim
{
    if (self = [self init])
    {
        _jsAnimation = [JSManagedValue managedValueWithValue:jsAnim];
        [jsAnim.context.virtualMachine addManagedReference:_jsAnimation withOwner:self];
        _jsCtx = jsAnim.context;
    }
    
    return self;
}


-(void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished
{
    
    if (_jsAnimation)
    {
        JSValue *realAnim = _jsAnimation.value;
        if (realAnim[@"completed"])
        {
            [realAnim[@"completed"] callWithArguments:@[realAnim]];
            _jsCtx = nil;
        }
    }
}


@end
