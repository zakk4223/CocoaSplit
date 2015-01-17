//
//  AWRenderer.h
//  CSBrowserCapturePlugin
//
//  Created by Zakk on 1/2/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Awesomium/WebCore.h>




@interface AWRenderer : NSObject
{
    IOSurfaceRef _renderSurface;
    Awesomium::WebCore *_webCore;
    Awesomium::WebView *webView;
    NSString *_myURL;
}



@end
