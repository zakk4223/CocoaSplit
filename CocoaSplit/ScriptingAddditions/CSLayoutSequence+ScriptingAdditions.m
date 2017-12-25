//
//  CSLayoutSequence+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 5/28/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSequence+ScriptingAdditions.h"
#import "CaptureController.h"
#import "PreviewView.h"

@implementation CSLayoutSequence (ScriptingAdditions)


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSNameSpecifier alloc]
            initWithContainerClassDescription:appDesc
            containerSpecifier:nil
            key:@"scripts"
            name:[self name]];
}


-(SourceLayout *)getUseLayout:(NSScriptCommand *)command
{
    SourceLayout *useLayout = [CaptureController sharedCaptureController].activePreviewView.sourceLayout;
    
    NSScriptObjectSpecifier *spec = command.arguments[@"useLayout"];
    
    if (spec)
    {
        useLayout = spec.objectsByEvaluatingSpecifier;
    }
    
    return useLayout;
}


-(void)scriptRun:(NSScriptCommand *)command
{
    SourceLayout *useLayout = [self getUseLayout:command];
    
    if (!self.lastRunUUID && !self.sourceLayout)
    {
        [self runSequenceForLayout:useLayout withCompletionBlock:nil withExceptionBlock:nil];
    }
}


-(void)scriptStop:(NSScriptCommand *)command
{
    [self cancelSequence];
}



@end
