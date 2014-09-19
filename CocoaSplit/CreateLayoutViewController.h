//
//  CreateLayoutViewController.h
//  CocoaSplit
//
//  Created by Zakk on 9/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CreateLayoutViewController : NSViewController

@property (weak) id textFieldDelegate;

- (IBAction)layoutNameEntered:(NSTextField *)sender;
@end
