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
#import "PreviewView.h"


@implementation CSPluginServices

+(CSPluginServices *) sharedPluginServices
{
    static CSPluginServices *sharedCSPluginServices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedCSPluginServices = [[self alloc] init];
    });
    
    return sharedCSPluginServices;
}







-(NSArray *)accountNamesForService:(NSString *)serviceName
{
    
    NSString *useServiceName = [NSString stringWithFormat:@"CocoaSplit-%@", serviceName];
    NSMutableDictionary *keyChainAttrs = [[NSMutableDictionary alloc] init];
    
    [keyChainAttrs setObject:(__bridge NSString *)kSecClassGenericPassword forKey:(__bridge NSString *)kSecClass];
    [keyChainAttrs setObject:useServiceName forKey:(__bridge NSString *)kSecAttrService];
    [keyChainAttrs setObject:(id)kCFBooleanTrue forKey:(__bridge NSString *)kSecReturnAttributes];
    [keyChainAttrs setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge NSString *)kSecMatchLimit];
    
    CFArrayRef resultArray = NULL;
    
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    
    SecItemCopyMatching((CFDictionaryRef)keyChainAttrs, (CFTypeRef *)&resultArray);
    
    
    for (NSDictionary *itemDict in (__bridge NSArray *)resultArray)
    {
        NSString *accountName = itemDict[(__bridge NSString *)kSecAttrAccount];
        [retArr addObject:accountName];
    }
    
    return retArr;
}


-(double) currentFPS
{
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
    if (myAppDelegate.captureController)
    {
        return myAppDelegate.captureController.captureFPS;
    }
    return 0.0;
}


-(int) audioSampleRate
{
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
    if (myAppDelegate.captureController)
    {
        return myAppDelegate.captureController.audioSamplerate;
    }
    return 0;
}



-(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void (^)(__unsafe_unretained Class))withBlock
{
    [CaptureController loadPythonClass:pyClass fromFile:fromFile withBlock:withBlock];
}


-(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile
{
    return [CaptureController loadPythonClass:pyClass fromFile:fromFile];
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


-(CSOauth2Authenticator *) createOAuth2Authenticator:(NSString *)serviceName clientID:(NSString *)client_id flowType:(NSString *)flow_type config:(NSDictionary *)config_dict;
{

    return [[CSOauth2Authenticator alloc] initWithServiceName:serviceName clientID:client_id flowType:flow_type config:config_dict];
}


@end
