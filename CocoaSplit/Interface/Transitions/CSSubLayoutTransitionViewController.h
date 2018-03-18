//
//  CSSubLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"

@interface CSSubLayoutTransitionViewController : NSViewController <NSPopoverDelegate>

@property (strong) NSDictionary *transitionNames;
@property (strong) NSString *transitionName;
@property (strong) NSObject<CSLayoutTransitionViewProtocol> *layoutTransitionViewController;
@property (weak) IBOutlet NSView *layoutTransitionConfigView;
@property (strong) CSTransitionBase *transition;

@end
