//
//  CAMultiAudioOutputTrack+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 5/27/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import "CAMultiAudioOutputTrack+ScriptingAdditions.h"

@implementation CAMultiAudioOutputTrack (ScriptingAdditions)

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:appDesc containerSpecifier:nil key:@"audioTracks" uniqueID:self.uuid];
    /*    return [[NSNameSpecifier alloc]
     initWithContainerClassDescription:appDesc
     containerSpecifier:nil
     key:@"layouts"
     name:[self name]];
     */
}

@end
