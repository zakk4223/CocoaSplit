//
//  HitboxStreamService.h
//  CSHitboxStreamServicePlugin
//
//  Created by Zakk on 12/1/14.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSStreamServiceBase.h"

#define HITBOX_API_BASE "https://api.hitbox.tv/"

@interface HitboxStreamService : CSStreamServiceBase <CSStreamServiceProtocol>


@property bool isReady;

@property (strong) NSString *authKey;
@property (strong) NSArray *ingestServers;
@property (strong) NSString *authUsername;
@property (strong) NSString *streamKey;
@property (strong) NSString *streamPath;
@property (strong) NSString *selectedServer;

-(NSViewController *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
-(void)authenticate:(NSString *)username password:(NSString *)password onComplete:(void(^)(void))callback;
-(void)fetchIngestServers:(void(^)(void))callback;
+(NSImage *)serviceImage;




@end
