//
//  CSLayoutLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

//This class name is terrible

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSSubLayoutTransitionViewController.h"

@interface CSLayoutLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>
{
    NSObject <CSLayoutTransitionViewProtocol> *_subTransitionViewController;
    NSPopover *_subPopover;
    
}


@property (strong) CSLayoutTransition *transition;

@property (strong) NSArray *sourceLayouts;

@property (strong) CSLayoutTransition *subTransition;

- (IBAction)configureInTransition:(id)sender;
- (IBAction)configureOutTransition:(id)sender;

@end
