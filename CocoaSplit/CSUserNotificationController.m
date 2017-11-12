//
//  CSUserNotificationController.m
//  CocoaSplit
//
//  Created by Zakk on 11/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSUserNotificationController.h"
#import "CSNotifications.h"
#import "OutputDestination.h"

@implementation CSUserNotificationController



-(instancetype) init
{
    if (self = [super init])
    {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputErrored:) name:CSNotificationOutputErrored object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputRestarted:) name:CSNotificationOutputRestarted object:nil];

        [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    }
    
    return self;
}


-(BOOL) userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


-(void)outputErrored:(NSNotification *)notification
{
    NSUserNotification *uNotice = [[NSUserNotification alloc] init];
    uNotice.title = @"Output Errored";
    OutputDestination *output = notification.object;
    
    uNotice.informativeText = output.name;
    uNotice.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:uNotice];
}

-(void)outputRestarted:(NSNotification *)notification
{
    NSUserNotification *uNotice = [[NSUserNotification alloc] init];
    uNotice.title = @"Output Restarted";
    OutputDestination *output = notification.object;
    
    uNotice.informativeText = output.name;
    uNotice.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:uNotice];
}



-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
