//
//  CSWebViewCapture.h
//  CSWebViewCapturePlugin
//
//  Created by Zakk on 7/21/17.
//

#import "CSCaptureBase.h"
#import "CSAbstractCaptureDevice.h"
#import <WebKit/WebKit.h>
#import <SceneKit/SceneKit.h>


@interface CSWebViewCapture : CSCaptureBase <CSCaptureSourceProtocol>

@property (strong) WKWebView *webView;
@property (strong) SCNScene *webScene;
@property (strong) SCNNode *webNode;
@property (strong) SCNNode *cameraNode;
@property (strong) SCNPlane *webPlane;
@property (strong) NSWindow *webWindow;
@end

