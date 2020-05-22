//
//  CSPluginServices.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPcmPlayer.h"
#import "CSOauth2Authenticator.h"
#import "CSSystemAudioOutput.h"
#import "CSSystemAudioNode.h"
#import <JavaScriptCore/JavaScriptCore.h>


@interface CSPluginServices : NSObject



+(CSPluginServices *)sharedPluginServices;
-(CSPcmPlayer *)createPCMInput:(NSString *)forUID withFormat:(AVAudioFormat *)withFormat;

-(void)removePCMInput:(CSPcmPlayer *)toRemove;
-(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void(^)(Class))withBlock;
-(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile;
-(NSString *)nameForAudioTrackUUID:(NSString *)uuid;


-(CSOauth2Authenticator *) createOAuth2Authenticator:(NSString *)serviceName clientID:(NSString *)client_id flowType:(NSString *)flow_type config:(NSDictionary *)config_dict;
-(NSArray *)accountNamesForService:(NSString *)serviceName;
-(NSObject *)captureController;
-(JSValue *)runJavascript:(NSString *)script;
-(NSString *)generateUUID;
-(NSDate *)streamStartDate;
-(NSArray *)audioOutputs;
-(CSSystemAudioOutput *)systemAudioOutputForFormat:(AVAudioFormat *)audioFormat forDevice:(CSSystemAudioOutput *)device;


@property (readonly) double currentFPS;
@property (readonly) int audioSampleRate;
@property (readonly) NSSize streamSizeHint;




@end
