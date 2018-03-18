//
//  CSSimpleLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/16/17.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "CSLayoutTransitionViewProtocol.h"

@interface CSSimpleLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>

@property (strong) NSArray *transitionDirections;
@property (strong) CSTransitionBase *transition;
@property (strong) NSPopover *popover;
@end

