//
//  CSSimpleLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/16/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "CSLayoutTransitionViewProtocol.h"

@interface CSSimpleLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>

@property (strong) NSArray *transitionDirections;
@property (strong) CSLayoutTransition *transition;

@end

