//
//  CSLayoutLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

//This class name is terrible

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSTransitionLayout.h"

@interface CSLayoutLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol, NSWindowDelegate>
{
    NSObject <CSLayoutTransitionViewProtocol> *_subTransitionViewController;
    NSPopover *_subPopover;
    NSWindow *_configWindow;
    NSViewController *_configViewController;
    
}


@property (strong) CSTransitionLayout *transition;

@property (strong) NSArray *sourceLayouts;

@property (strong) CSTransitionBase *subTransition;
@property (strong) NSPopover *popover;

- (IBAction)configureInTransition:(id)sender;
- (IBAction)configureOutTransition:(id)sender;
-(IBAction)openInputConfigWindow:(id)sender;

@end
