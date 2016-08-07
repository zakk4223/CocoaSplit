//
//  CSAnimationChooserViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/26/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"

@interface CSAnimationChooserViewController : NSViewController <NSPopoverDelegate>


@property (weak) NSPopover *popover;

@property (strong) SourceLayout *sourceLayout;
@property (strong) NSMutableArray *animationList;
@property (strong) NSIndexSet *selectedAnimations;
@property (strong) NSDictionary *selectedAnimation;

- (IBAction)addButtonClicked:(id)sender;

@end
