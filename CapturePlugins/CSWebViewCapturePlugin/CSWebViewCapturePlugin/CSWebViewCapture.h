//
//  CSWebViewCapture.h
//  CSWebViewCapturePlugin
//
//  Created by Zakk on 4/8/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"
#import <WebKit/WebKit.h>
#import "CSWebViewView.h"

@interface CSWebViewCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    CSWebViewView *_webView;
    NSWindow *_webWindow;
    NSBitmapImageRep *_imageRep;
    
}



@end
