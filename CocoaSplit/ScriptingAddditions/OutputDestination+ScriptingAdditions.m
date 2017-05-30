//
//  OutputDestination+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 5/28/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "OutputDestination+ScriptingAdditions.h"

@implementation OutputDestination (ScriptingAdditions)

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSNameSpecifier alloc]
            initWithContainerClassDescription:appDesc
            containerSpecifier:nil
            key:@"captureDestinations"
            name:[self name]];
}



-(bool) scriptRunning
{
    return self.captureRunning && self.active;
}
@end
