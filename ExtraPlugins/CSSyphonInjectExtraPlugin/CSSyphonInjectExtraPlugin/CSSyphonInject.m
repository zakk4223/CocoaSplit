//
//  CSSyphonInject.m
//  CSSyphonInjectExtraPlugin
//
//  Created by Zakk on 10/1/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSSyphonInject.h"
#import <ScriptingBridge/ScriptingBridge.h>


@implementation CSSyphonInject



+(NSString *)label
{
    return @"SyphonInject";
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    
    return;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    
    return self;
    
    
}
-(void)extraTopLevelMenuClicked
{
    
    self.sharedWorkspace = [NSWorkspace sharedWorkspace];
    
    
    _windowController = [[CSSyphonInjectWindowController alloc] initWithWindowNibName:@"CSSyphonInjectWindowController"];
    [_windowController showWindow:nil];
    _windowController.injector = self;
}

- (void)doInject:(NSRunningApplication *)toInject
{
    
        
        pid_t pid = toInject.processIdentifier;
        
        SBApplication *sbapp = [SBApplication applicationWithProcessIdentifier:pid];
        
        //[sbapp setDelegate:self];
        
        
        
        
        [sbapp setTimeout:10*60];
        
        [sbapp setSendMode:kAEWaitReply];
        [sbapp sendEvent:'ascr' id:'gdut' parameters:0];
        [sbapp setSendMode:kAENoReply];
        [sbapp sendEvent:'SASI' id:'injc' parameters:0];
    
}


@end
