//
//  TwitchStreamService.h
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSPluginServices.h"
#import "CSOauth2Authenticator.h"


@interface TwitchStreamService : NSObject <CSStreamServiceProtocol>
{
    NSString *_oauth_client_id;
}


@property bool isReady;

@property (strong) NSArray *twitchServers;
@property (strong) NSString *streamKey;
@property (strong) NSString *selectedServer;
@property (strong) NSString *oAuthKey;
@property (strong) CSOauth2Authenticator *oauthObject;



-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
-(void)fetchTwitchStreamKey;
+(NSString *)label;
+(NSString *)serviceDescription;



@end
