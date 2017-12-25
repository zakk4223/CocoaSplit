//
//  CSCIFilterLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"


@interface CSCIFilterLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>

@property (strong) CSLayoutTransition *transition;

@property (strong) NSWindow *transitionFilterWindow;

-(IBAction)openTransitionFilterPanel:(NSButton *)sender;



@end
