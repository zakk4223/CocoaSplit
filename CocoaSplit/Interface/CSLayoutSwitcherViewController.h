//
//  CSLayoutSwitcherViewController.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutSwitcherView.h"

@interface CSLayoutSwitcherViewController : NSViewController
@property (strong) NSArray *layouts;
@property (assign) bool isSwitcherView;
@property (strong) NSMenu *layoutMenu;

-(void)buildLayoutMenuForView:(CSLayoutSwitcherView *)view;
-(void)showLayoutMenu:(NSEvent *)clickEvent forView:(CSLayoutSwitcherView *)view;


@end
