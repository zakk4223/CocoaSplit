//
//  CSSyphonInjectCaptureViewController.m
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//

#import "CSSyphonInjectCaptureViewController.h"

@interface CSSyphonInjectCaptureViewController ()

@end

@implementation CSSyphonInjectCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    if (self.notInstalledTextField)
    {
        self.notInstalledTextField.allowsEditingTextAttributes = YES;
        self.notInstalledTextField.selectable = YES;
    
        self.notInstalledTextField.attributedStringValue = self.notInstalledText;
    }
    
    self.renderStyleMap = @{@"On Frame Arrival": @(kCSRenderFrameArrived),
                            @"On Internal Frame Tick": @(kCSRenderOnFrameTick),
                            @"Asynchronous": @(kCSRenderAsync)
                            };
    
    self.styleSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]];

    // Do view setup here.
}



-(NSAttributedString *)notInstalledText
{
    NSMutableAttributedString *retStr = [[NSMutableAttributedString alloc] initWithString:@"A compatible version of SyphonInject is not installed. Download and install the latest version from "];
    
    NSMutableAttributedString *urlStr = [[NSMutableAttributedString alloc] initWithString:@"here"];
    
    
    NSRange range = NSMakeRange(0, urlStr.length);
    
    [urlStr beginEditing];
    
    NSURL *URL = [NSURL URLWithString:@"http://www.cocoasplit.com/releases/SyphonInject/SyphonInject.zip"];
    
    [urlStr addAttribute:NSLinkAttributeName value:URL range:range];
    
    [urlStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [urlStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    [urlStr endEditing];
    
    [retStr appendAttributedString:urlStr];
    
    return retStr;
}


- (IBAction)changeBuffer:(id)sender
{
    [self.captureObj changeBuffer];
}

- (IBAction)toggleFast:(id)sender
{
    [self.captureObj toggleFast];
}

- (IBAction)setDimensions:(id)sender
{
    [self.captureObj setBufferDimensions:self.x_offset y_offset:self.y_offset width:self.width height:self.height];
}


@end
