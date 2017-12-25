//
//  CSSequenceItemTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/20/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemViewController.h"
#import "CaptureController.h"

@interface CSSequenceItemTransitionViewController : CSSequenceItemViewController

@property (weak) CaptureController *captureController;
@property (strong) NSWindow *transitionFilterWindow;
-(IBAction)openTransitionFilterPanel:(NSButton *)sender;

@end
