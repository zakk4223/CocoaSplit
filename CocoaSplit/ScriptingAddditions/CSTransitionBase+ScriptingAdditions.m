//
//  CSTransitionBase+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 4/8/18.

//

#import "CSTransitionBase+ScriptingAdditions.h"
#import "CaptureController.h"



@implementation CSTransitionBase (ScriptingAdditions)

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSNameSpecifier alloc]
            initWithContainerClassDescription:appDesc
            containerSpecifier:nil
            key:@"transitions"
            name:[self name]];
}
    -(void)scriptActivate:(NSScriptCommand *)command
    {
        [CaptureController sharedCaptureController].activeTransition = self;
    }
    
    -(void)scriptDeactivate:(NSScriptCommand *)command
    {
        if (self.active)
        {
            [CaptureController sharedCaptureController].activeTransition = nil;
        }
    }
    
    -(void)scriptToggle:(NSScriptCommand *)command
    {
        if (self.active)
        {
            [self scriptDeactivate:command];
        } else {
            [self scriptActivate:command];
        }
    }

    -(void)scriptToggleLive:(NSScriptCommand *)command
    {
        if (!self.canToggle)
        {
            return;
        }
        self.isToggle = YES;
        if (self.isToggle)
        {
            self.active = !self.active;
            if (!self.active)
            {
                self.isToggle = NO;
            }
        }
    }
@end
