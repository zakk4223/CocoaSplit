//
//  SourceLayout+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 9/1/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SourceLayout+ScriptingAdditions.h"
#import "AppDelegate.h"
#import "AppDelegate+AppDelegate_ScriptingAdditions.h"



@implementation SourceLayout (ScriptingAdditions)


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSNameSpecifier alloc]
             initWithContainerClassDescription:appDesc
             containerSpecifier:nil
             key:@"layouts"
             name:[self name]];
}


-(void)scriptActivate:(NSScriptCommand *)command
{
    
    AppDelegate *delegate = [NSApplication sharedApplication].delegate;
    [delegate setActiveLayout:self];
    
}
@end
