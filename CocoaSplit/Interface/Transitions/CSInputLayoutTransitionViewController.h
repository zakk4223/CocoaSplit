//
//  CSInputLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 4/1/18.
//

#import <Cocoa/Cocoa.h>
#import "CSTransitionInput.h"

@interface CSInputLayoutTransitionViewController : NSViewController
    {
        NSViewController *_configViewController;
    }
    @property (strong) CSTransitionInput *transition;
    @property (strong) NSPopover *popover;
    @property (weak) IBOutlet NSView *inputConfigView;
@end
