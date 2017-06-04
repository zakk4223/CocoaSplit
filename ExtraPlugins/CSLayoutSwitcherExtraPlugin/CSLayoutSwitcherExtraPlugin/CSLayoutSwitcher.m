//
//  CSLayoutSwitcher.m
//  CSLayoutSwitcherExtraPlugin
//
//  Created by Zakk on 9/5/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSLayoutSwitcher.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation CSLayoutSwitcher



-(id)initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [self init])
    {
        self.switchActions = [aDecoder decodeObjectForKey:@"switchActions"];
    }
    
    return self;
}



-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.switchActions forKey:@"switchActions"];
}


+(NSString *)label
{
    return @"LayoutSwitcher";
}

-(void)pluginWasLoaded
{
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(applicationActivated:) name:NSWorkspaceDidActivateApplicationNotification  object:[NSWorkspace sharedWorkspace]];
    
    
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(applicationDeactivated:) name:NSWorkspaceDidDeactivateApplicationNotification  object:[NSWorkspace sharedWorkspace]];
    

}
-(void)extraTopLevelMenuClicked
{
    
    
    if (!self.switchActions)
    {
        self.switchActions = [NSMutableArray array];
        
    }
    _windowController = [[CSLayoutSwitcherWindowController alloc] initWithWindowNibName:@"CSLayoutSwitcherWindowController"];
    [_windowController showWindow:nil];
    _windowController.layoutSwitcher = self;
}

-(void) applicationDeactivated:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSRunningApplication *activatedApp = userInfo[NSWorkspaceApplicationKey];
    
    [self doLayoutSwitch:activatedApp.localizedName forEvent:kEventDeactivated];
}


-(void) applicationActivated:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSRunningApplication *activatedApp = userInfo[NSWorkspaceApplicationKey];
    [self doLayoutSwitch:activatedApp.localizedName forEvent:kEventActivated];
    
    
}

-(void)doLayoutSwitch:(NSString *)appname forEvent:(layout_switch_event)forEvent
{
    
    CSLayoutSwitchAction *matchedAction = nil;
    for(CSLayoutSwitchAction *act in self.switchActions)
    {
        if (!act.active)
        {
            continue;
        }
        
        
        if (act.eventType != forEvent)
        {
            continue;
        }
        
        if ([appname rangeOfString:act.applicationString].location != NSNotFound)
        {
            matchedAction = act;
            break;
        }
    }
    
    
    if (matchedAction)
    {
        NSMutableString *scriptSrc = [NSMutableString string];
        
        if (matchedAction.targetName)
        {
            NSString *verb = nil;
            NSString *subjectType = nil;
            
            switch(matchedAction.actionType)
            {
                case kScriptRun:
                    verb = @"run";
                    subjectType = @"layoutscript";
                    break;
                case kScriptStop:
                    verb = @"stop";
                    subjectType = @"layoutscript";
                    break;
                case kLayoutMerge:
                    verb = @"merge";
                    subjectType = @"layout";
                case kLayoutRemove:
                    verb = @"remove";
                    subjectType = @"layout";
                    break;
                case kLayoutSwitch:
                    verb = @"replace with";
                    subjectType = @"layout";
                    break;
                default:
                    verb = nil;
                    subjectType = nil;
                    break;
            }
            
            if (verb && subjectType)
            {
                NSString *scriptSrc = [NSString stringWithFormat:@"%@ %@ \"%@\"", verb, subjectType, matchedAction.targetName];
                NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSrc];
                [script executeAndReturnError:nil];
            }
        }
        
    }
}

- (void)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    
    return;
}

@end
