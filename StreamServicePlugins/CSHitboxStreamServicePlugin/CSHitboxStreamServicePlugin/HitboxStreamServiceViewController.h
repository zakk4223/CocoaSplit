//
//  HitboxStreamServiceViewController.h
//  CSHitboxStreamServicePlugin
//
//  Created by Zakk on 12/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HitboxStreamService.h"

@interface HitboxStreamServiceViewController : NSViewController


@property (strong) NSString *password;

@property (weak) HitboxStreamService *serviceObj;

@property (weak) IBOutlet NSTextField *loginFailedText;

@property (weak) IBOutlet NSProgressIndicator *loginProgressIndicator;
- (IBAction)loginClicked:(id)sender;

@end
