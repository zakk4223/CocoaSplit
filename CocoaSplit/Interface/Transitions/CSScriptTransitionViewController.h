//
//  CSScriptTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/29/18.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSTransitionScript.h"

@interface CSScriptTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>


@property (strong) CSTransitionScript *transition;

@property (strong) NSPopover *popover;
@end
