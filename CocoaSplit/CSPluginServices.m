//
//  CSPluginServices.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSPluginServices.h"
#import "CAMultiAudioPCMPlayer.h"
#import "CSPcmPlayer.h"
#import "AppDelegate.h"


@implementation CSPluginServices

+(id) sharedPluginServices
{
    static CSPluginServices *sharedCSPluginServices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedCSPluginServices = [[self alloc] init];
    });
    
    return sharedCSPluginServices;
}


-(void)removePCMInput:(CSPcmPlayer *)toRemove
{
    
    CAMultiAudioPCMPlayer *realRemove = (CAMultiAudioPCMPlayer *)toRemove;
    
    
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
    if (myAppDelegate.captureController && myAppDelegate.captureController.multiAudioEngine)
    {
        
        [myAppDelegate.captureController.multiAudioEngine removePCMInput:realRemove];
    }
}


-(CSPcmPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat
{
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
    
    
    
    
    if (myAppDelegate.captureController && myAppDelegate.captureController.multiAudioEngine)
    {
        
        CAMultiAudioPCMPlayer *player;
        
        player = [myAppDelegate.captureController.multiAudioEngine createPCMInput:forUID withFormat:withFormat];
        return (CSPcmPlayer *)player;
    }
    
    return nil;
}


@end
