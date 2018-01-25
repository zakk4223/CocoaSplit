//
//  TwitchStreamService.h
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSPluginServices.h"
#import "CSOauth2Authenticator.h"
#import "CSStreamServiceBase.h"

@interface TwitchStreamService : CSStreamServiceBase <CSStreamServiceProtocol>
{
    NSString *_oauth_client_id;
    bool _key_fetch_pending;
}



@property (strong) NSArray *twitchServers;
@property (strong) NSString *streamKey;
@property (strong) NSString *selectedServer;
@property (strong) NSString *oAuthKey;
@property (strong) CSOauth2Authenticator *oauthObject;
@property (strong) NSString *accountName;
@property (assign) bool alwaysFetchKey;
@property (strong) NSArray *knownAccounts;
@property (assign) bool bandwidthTest;







-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
-(void)fetchTwitchStreamKey;
+(NSString *)label;
+(NSString *)serviceDescription;
-(void)authenticateUser;
+(NSImage *)serviceImage;




@end
