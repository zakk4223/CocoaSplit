//
//  CSSequenceItemAnimationViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/26/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemViewController.h"
#import "CaptureController.h"

@interface CSSequenceItemAnimationViewController : CSSequenceItemViewController
@property (weak) CaptureController *captureController;
@property (strong) NSArray *animationList;

@end
