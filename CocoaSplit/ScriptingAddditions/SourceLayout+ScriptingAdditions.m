//
//  SourceLayout+ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 9/1/14.
//

#import "SourceLayout+ScriptingAdditions.h"
#import "AppDelegate.h"
#import "AppDelegate+AppDelegate_ScriptingAdditions.h"
#import "PreviewView.h"



@implementation SourceLayout (ScriptingAdditions)


- (NSScriptObjectSpecifier *)objectSpecifier {
    NSScriptClassDescription* appDesc
    = (NSScriptClassDescription*)[NSApp classDescription];
    return [[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:appDesc containerSpecifier:nil key:@"layouts" uniqueID:self.uuid];
/*    return [[NSNameSpecifier alloc]
             initWithContainerClassDescription:appDesc
             containerSpecifier:nil
             key:@"layouts"
             name:[self name]];
 */
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


-(void)scriptRecord:(NSScriptCommand *)command
{
    [[CaptureController sharedCaptureController] startRecordingLayout:self];
}

-(void)scriptStopRecord:(NSScriptCommand *)command
{
    [[CaptureController sharedCaptureController] stopRecordingLayout:self];
}

-(void)scriptToggleLayout:(NSScriptCommand *)command
{
    
    SourceLayout *useLayout = [self getUseLayout:command];
    NSString *sourceOrder = command.arguments[@"sourceOrder"];
    
    useLayout.sourceAddOrder = kCSSourceAddOrderAny;
    if (sourceOrder)
    {
        if ([sourceOrder isEqualToString:@"above"])
        {
            useLayout.sourceAddOrder = kCSSourceAddOrderTop;
        } else if ([sourceOrder isEqualToString:@"below"]) {
            useLayout.sourceAddOrder = kCSSourceAddOrderBottom;
        }
    }
    [[CaptureController sharedCaptureController] toggleLayout:self usingLayout:useLayout];
}

-(void)scriptMergeLayout:(NSScriptCommand *)command
{
    SourceLayout *useLayout = [self getUseLayout:command];

    
    NSString *sourceOrder = command.arguments[@"sourceOrder"];
    
    useLayout.sourceAddOrder = kCSSourceAddOrderAny;
    if (sourceOrder)
    {
        if ([sourceOrder isEqualToString:@"above"])
        {
            useLayout.sourceAddOrder = kCSSourceAddOrderTop;
        } else if ([sourceOrder isEqualToString:@"below"]) {
            useLayout.sourceAddOrder = kCSSourceAddOrderBottom;
        }
    }
    
    [[CaptureController sharedCaptureController] mergeLayout:self usingLayout:useLayout];
}

-(void)scriptRemoveLayout:(NSScriptCommand *)command
{
    SourceLayout *useLayout = [self getUseLayout:command];
    
    [[CaptureController sharedCaptureController] removeLayout:self usingLayout:useLayout];
}


-(void)scriptSwitchToLayout:(NSScriptCommand *)command
{

    SourceLayout *useLayout = [self getUseLayout:command];

    [[CaptureController sharedCaptureController] switchToLayout:self usingLayout:useLayout];
}


-(void)scriptActivate:(NSScriptCommand *)command
{
    
    AppDelegate *delegate = [NSApplication sharedApplication].delegate;
    [delegate setActiveLayout:self];
    
}

-(NSArray *)sources
{
    NSArray *ret = self.sourceListOrdered;
    return ret;
}

- (unsigned int)countOfSources {
    return (unsigned int)self.sourceListOrdered.count;
}



@end
