//
//  InputSource+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 10/20/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "InputSource+ScriptingAdditions.h"
#import "SourceLayout.h"

@implementation InputSource (ScriptingAdditions)

- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* layoutClassDesc = (NSScriptClassDescription*)[self.sourceLayout classDescription];
    NSNameSpecifier *layoutSpecifier = (NSNameSpecifier *)[self.sourceLayout objectSpecifier];
    return [[NSNameSpecifier alloc]
            initWithContainerClassDescription:layoutClassDesc
            containerSpecifier:layoutSpecifier
            key:@"sources"
            name:[self name]];
}

@end
