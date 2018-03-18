//
//  CSLayoutTransitionViewProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/16/17.
//

#import <Foundation/Foundation.h>
@class CSTransitionBase;

@protocol CSLayoutTransitionViewProtocol <NSObject, NSPopoverDelegate>

@property (strong) CSTransitionBase *transition;
@property (strong) NSPopover *popover;
@property (strong) NSView *view;

@end
