//
//  CSOauth2Authenticator.h
//  CocoaSplit
//
//  Created by Zakk on 7/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

extern NSString *const kCSOauth2ConfigRedirectURL;
extern NSString *const kCSOauth2ConfigScopes;
extern NSString *const kCSOauth2ConfigAuthURL;
extern NSString *const kCSOauth2AccessTokenRequestURL;
extern NSString *const kCSOauth2AccessRefreshURL;
extern NSString *const kCSOauth2CodeFlow;
extern NSString *const kCSOauth2ImplicitGrantFlow;
extern NSString *const kCSOauth2ExtraAuthParams;
extern NSString *const kCSOauth2ClientSecret;






@interface CSOauth2Authenticator : NSObject <WebPolicyDelegate>
{
    NSWindow *_authWindow;
    WebView *_authWebView;
    void (^_authorizeCallback)(bool success);
}


@property (strong) NSString *clientID;
@property (assign) bool forceVerify;
@property (strong) NSURL *authURL;
@property (strong) NSString *serviceName;
@property (strong) NSString *accessToken;
@property (strong) NSString *accountName;
@property (assign) bool useKeychain;
@property (strong) NSString *flowType;

@property (nonatomic, copy) void(^accountNameFetcher)(CSOauth2Authenticator *authenticator);
@property (strong) NSDictionary *extraAuthParams;




-(instancetype) initWithServiceName:(NSString *)serviceName clientID:(NSString *)client_id flowType:(NSString *)flow_type config:(NSDictionary *)config_dict;


-(void)jsonRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(id decodedData))handler;

-(void)saveToKeychain:(NSString *)accountName;
-(void)authorize:(void (^)(bool success))authCallback;
-(void)configurationVariableSet:(id)val forName:(NSString *)forName;
-(id)configurationVariableGet:(NSString *)forName;
-(id)configurationVariableRemove:(NSString *)forName;



@end
