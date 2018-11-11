//
//  CSAppleWebViewCaptureViewController.h
//  CSAppleWebViewCapturePlugin
//
//  Created by Zakk on 11/4/18.
//

#import <Cocoa/Cocoa.h>
#import "CSAppleWebViewCapture.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSAppleWebViewCaptureViewController : NSViewController <NSWindowDelegate>
@property (weak) CSAppleWebViewCapture *captureObj;
@property (strong, nullable) NSWindow *viewWindow;
- (IBAction)openTestWindow:(id)sender;
@end

NS_ASSUME_NONNULL_END
