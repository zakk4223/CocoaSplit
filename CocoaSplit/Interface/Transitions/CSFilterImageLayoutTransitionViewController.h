//
//  CSFilterImageLayoutTransitionViewController.h
//  CocoaSplit
//
//  Created by Zakk on 1/23/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutTransitionViewProtocol.h"
#import "CSTransitionImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSFilterImageLayoutTransitionViewController : NSViewController <CSLayoutTransitionViewProtocol>
@property (strong) CSTransitionImageFilter *transition;
@property (strong) NSWindow *transitionFilterWindow;
@property (strong) NSPopover *popover;

-(IBAction)openTransitionFilterPanel:(NSButton *)sender;
-(IBAction)openFilterChooser:(NSButton *)sender;
@end


NS_ASSUME_NONNULL_END
