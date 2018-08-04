//
//  CSYoutubeStreamService.h
//  CSYoutubeStreamServicePlugin
//
//  Created by Zakk on 7/24/16.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSPluginServices.h"
#import "CSOauth2Authenticator.h"
#import "CSStreamServiceBase.h"

@interface CSYoutubeStreamService : CSStreamServiceBase <CSStreamServiceProtocol>
{
    NSString *_currentStreamDest;
    bool _destination_fetch_pending;
    NSString *_saved_selected_streamID;
    NSString *_oauth_client_id;
    NSString *_oauth_client_secret;
    
}



-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
-(void)authenticateUser;
+(NSImage *)serviceImage;



@property (strong) NSString *accountName;
@property (strong) CSOauth2Authenticator *oauthObject;
@property (strong) NSArray *liveStreams;
@property (strong) NSDictionary *selectedLiveStream;
@property (strong) NSArray *knownAccounts;

@end
