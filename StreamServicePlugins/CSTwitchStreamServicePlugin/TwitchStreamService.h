//
//  TwitchStreamService.h
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"


@interface TwitchStreamService : NSObject <CSStreamServiceProtocol>


@property bool isReady;

@property (strong) NSArray *twitchServers;
@property (strong) NSString *streamKey;
@property (strong) NSString *selectedServer;
@property (strong) NSString *oAuthKey;



-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
-(void)fetchTwitchStreamKey;
+(NSString *)label;
+(NSString *)serviceDescription;



@end
