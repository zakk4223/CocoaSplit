//
//  CSNDICaptureViewController.m
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/20/18.
//

#import "CSNDICaptureViewController.h"
#import "CSNDICapture.h"

@interface CSNDICaptureViewController ()

@end

@implementation CSNDICaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.descriptionTextField)
    {
        self.descriptionTextField.allowsEditingTextAttributes = YES;
        self.descriptionTextField.selectable = YES;
        
        self.descriptionTextField.attributedStringValue = self.descriptionText;
    }
    // Do view setup here.
}


-(NSAttributedString *)descriptionText
{
    
    NDIlib_v3 *dispatch = [CSNDICapture ndi_dispatch_ptr];
    
    
    
    NSString *iStr;
    
    if (dispatch)
    {
        iStr = @"installed";
    } else {
        iStr = @"not installed";
    }
    NSString *availableStr = [NSString stringWithFormat:@"NDI runtime is %@\nYou can download the latest NDI runtime from ", iStr];
    NSMutableAttributedString *retStr = [[NSMutableAttributedString alloc] initWithString:availableStr];
    
    NSMutableAttributedString *urlStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:NDILIB_REDIST_URL]];
    
    
    NSRange range = NSMakeRange(0, urlStr.length);
    
    [urlStr beginEditing];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithUTF8String:NDILIB_REDIST_URL]];
    
    [urlStr addAttribute:NSLinkAttributeName value:URL range:range];
    
    [urlStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [urlStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    [urlStr endEditing];
    
    [retStr appendAttributedString:urlStr];
    
    return retStr;
}
@end
