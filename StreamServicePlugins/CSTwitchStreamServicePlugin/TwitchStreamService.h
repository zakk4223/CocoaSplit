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
    bool _key_fetch_pending;
}


@property bool isReady;

@property (strong) NSArray *twitchServers;
@property (strong) NSString *streamKey;
@property (strong) NSString *selectedServer;
@property (strong) NSString *oAuthKey;
@property (strong) CSOauth2Authenticator *oauthObject;
@property (strong) NSString *accountName;
@property (assign) bool alwaysFetchKey;
@property (strong) NSArray *knownAccounts;






-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
-(void)fetchTwitchStreamKey;
+(NSString *)label;
+(NSString *)serviceDescription;
-(void)authenticateUser;




@end
