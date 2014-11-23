//
//  CSPluginServices.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSPluginServices.h"
#import "CAMultiAudioPCMPlayer.h"
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


-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat
{
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
    
    
    
    
    if (myAppDelegate.captureController && myAppDelegate.captureController.multiAudioEngine)
    {
        
        return [myAppDelegate.captureController.multiAudioEngine createPCMInput:forUID withFormat:withFormat];
    }
    
    return nil;
}


@end
