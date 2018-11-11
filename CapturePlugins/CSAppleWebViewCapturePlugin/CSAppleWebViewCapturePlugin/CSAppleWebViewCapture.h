//
//  CSAppleWebViewCapture.h
//  CSAppleWebViewCapturePlugin
//
//  Created by Zakk on 11/3/18.
//

#import "CSCaptureBase.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSAppleWebViewCapture : CSCaptureBase <CSCaptureSourceProtocol, WKNavigationDelegate>
{
    dispatch_semaphore_t _frameSemaphore;
}

@property (strong) WKWebView *webView;

@property (strong) NSString *webURL;
@property (assign) int browser_width;
@property (assign) int browser_height;
@property (assign) bool useWindowCapture;
@property (strong) NSWindow *browserWindow;

@end

NS_ASSUME_NONNULL_END
