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
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:appDesc containerSpecifier:nil key:@"audioInputs" uniqueID:self.nodeUID];
}


-(void)scriptMute:(NSScriptCommand *)command
{
    self.enabled = NO;
}

-(void)scriptUnmute:(NSScriptCommand *)command
{
    self.enabled = YES;
}


@end
