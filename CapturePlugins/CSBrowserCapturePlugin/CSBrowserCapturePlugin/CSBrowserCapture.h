//
//  CSBrowserCapture.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/1/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"
#import <WebKit/WebKit.h>

@interface CSBrowserCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    WebView *_webview;

    CIImage *_currentImage;
    NSWindow *_webWindow;
    CGContextRef _cgcontext;
    bool _contentLoaded;
    dispatch_queue_t _renderQueue;
    dispatch_source_t _render_timer;
}


@property (strong) NSString *url;


@end
