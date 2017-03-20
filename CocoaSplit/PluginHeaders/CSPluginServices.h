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


@interface CSPluginServices : NSObject



+(CSPluginServices *)sharedPluginServices;
-(CSPcmPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat;

-(void)removePCMInput:(CSPcmPlayer *)toRemove;
-(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void(^)(Class))withBlock;
-(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile;



-(CSOauth2Authenticator *) createOAuth2Authenticator:(NSString *)serviceName clientID:(NSString *)client_id flowType:(NSString *)flow_type config:(NSDictionary *)config_dict;
-(NSArray *)accountNamesForService:(NSString *)serviceName;


@property (readonly) double currentFPS;
@property (readonly) int audioSampleRate;


@end
