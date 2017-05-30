//
//  CAMultiAudioNode+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 5/28/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode+ScriptingAdditions.h"

@implementation CAMultiAudioNode (ScriptingAdditions)

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSNameSpecifier alloc]
            initWithContainerClassDescription:appDesc
            containerSpecifier:nil
            key:@"audioInputs"
            name:[self name]];
}

@end
