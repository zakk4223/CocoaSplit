//
//  CSSequenceItemLayoutViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/19/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemViewController.h"
#import "AppDelegate.h"

@interface CSSequenceItemLayoutViewController : CSSequenceItemViewController
@property (weak) CaptureController *captureController;
@property (strong) NSDictionary *actionMap;
@end
