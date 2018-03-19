//
//  CSCIFilterLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSTransitionCIFilter.h"

@interface CSCIFilterLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>

@property (strong) CSTransitionCIFilter *transition;

@property (strong) NSWindow *transitionFilterWindow;
@property (strong) NSPopover *popover;

-(IBAction)openTransitionFilterPanel:(NSButton *)sender;



@end
