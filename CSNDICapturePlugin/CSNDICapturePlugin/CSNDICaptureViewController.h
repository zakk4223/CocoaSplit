//
//  CSNDICaptureViewController.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/20/18.
//

#import <Cocoa/Cocoa.h>

@interface CSNDICaptureViewController : NSViewController
@property (weak) NSObject *captureObj;

@property (weak) IBOutlet NSTextField *descriptionTextField;
@property (readonly) NSAttributedString *descriptionText;

@end
