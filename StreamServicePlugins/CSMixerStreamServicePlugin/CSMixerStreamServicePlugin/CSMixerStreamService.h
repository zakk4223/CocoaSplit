//
//  CSMixerStreamService.h
//  CSMixerStreamServicePlugin
//
//  Created by Zakk on 4/13/18.
//

#import "CSStreamServiceBase.h"
#import "CSStreamServiceProtocol.h"
#import "CSPluginServices.h"
#import "CSOauth2Authenticator.h"

@interface CSMixerStreamService : CSStreamServiceBase <CSStreamServiceProtocol>
{
    NSString *_oauth_client_id;
    NSNumber *_channel_id;
    bool _key_fetch_pending;

}

@property (strong) NSString *oAuthKey;
@property (strong) CSOauth2Authenticator *oauthObject;
@property (strong) NSArray *ingests;
@property (strong) NSDictionary *selectedIngest;
@property (strong) NSString *accountName;
@property (strong) NSArray *knownAccounts;
@property (strong) NSString *streamKey;
@property (assign) bool alwaysFetchKey;


-(void)authenticateUser;
-(void)fetchStreamKey;



@end
