//
//  CSOauth2Authenticator.h
//  CocoaSplit
//
//  Created by Zakk on 7/17/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface CSOauth2Authenticator : NSObject <WebPolicyDelegate>
{
    NSWindow *_authWindow;
    WebView *_authWebView;
    void (^_authorizeCallback)(bool success);
}


@property (strong) NSString *authLocation;
@property (strong) NSString *redirectURL;
@property (strong) NSArray *authScopes;
@property (strong) NSString *clientID;
@property (assign) bool forceVerify;
@property (strong) NSURL *authURL;
@property (strong) NSString *serviceName;
@property (strong) NSString *accessToken;


-(instancetype) initWithServiceName:(NSString *)serviceName authLocation:(NSString *)auth_location clientID:(NSString *)client_id redirectURL:(NSString *)redirect_url authScopes:(NSArray *)scopes forceVerify:(bool)force_verify;

-(void)jsonRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(id decodedData))handler;


@end
