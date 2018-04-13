//
//  TwitchStreamServiceViewController.h
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//


#import <Cocoa/Cocoa.h>
#import "TwitchStreamService.h"
#import <WebKit/WebKit.h>

@interface TwitchStreamServiceViewController : NSViewController <WebPolicyDelegate>

@property (weak) TwitchStreamService *serviceObj;
@property (strong) NSWindow *authWindow;
@property (strong) WebView *authWebView;
@property (strong) NSArray *serverSortDescriptors;

- (IBAction)doTwitchAuth:(id)sender;
- (IBAction)doTwitchstreamkey:(id)sender;

@end
