//
//  CSYoutubeStreamServiceViewController.h
//  CSYoutubeStreamServicePlugin
//
//  Created by Zakk on 7/24/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSYoutubeStreamService.h"

@interface CSYoutubeStreamServiceViewController : NSViewController

@property (weak) CSYoutubeStreamService *serviceObj;
- (IBAction)authenticateUser:(id)sender;

@end
