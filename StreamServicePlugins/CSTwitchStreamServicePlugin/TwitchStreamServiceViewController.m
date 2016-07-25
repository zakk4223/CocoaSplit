//
//  TwitchStreamServiceViewController.m
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "TwitchStreamServiceViewController.h"


@interface TwitchStreamServiceViewController ()

@end

@implementation TwitchStreamServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.serverSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
        
    }
    return self;
}



-(NSString *)extractAccessTokenFromURL:(NSURL *)url
{
    NSURLComponents *urlComp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *urlFragment = urlComp.percentEncodedFragment;
    
    NSURLComponents *fakeComponents = [NSURLComponents componentsWithString:[NSString stringWithFormat:@"http://localhost/blah?%@", urlFragment]];

    NSArray *queryVars = fakeComponents.queryItems;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", @"access_token"];
    NSURLQueryItem *tokenItem = [queryVars filteredArrayUsingPredicate:predicate].firstObject;
    
    return tokenItem.value;
}


- (IBAction)doTwitchAuth:(id)sender
{
    
    [self.serviceObj authenticateUser];
     
}

- (IBAction)doTwitchstreamkey:(id)sender
{
    [self.serviceObj fetchTwitchStreamKey];

}


-(void)closeAuthWindow
{
    self.authWindow = nil;
}


-(void)receivedOAuth:(NSString *)oToken
{
    self.serviceObj.oAuthKey = oToken;
    [self.serviceObj fetchTwitchStreamKey];
    
}


-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSURL *reqUrl = request.URL;
    if (reqUrl)
    {
        if ([reqUrl.scheme isEqualToString:@"cocoasplit-twitch"])
        {
            [listener ignore];
            NSString *accessToken = [self extractAccessTokenFromURL:reqUrl];
            [self receivedOAuth:accessToken];
            [self closeAuthWindow];

        }
    }

    [listener use];
}

@end
