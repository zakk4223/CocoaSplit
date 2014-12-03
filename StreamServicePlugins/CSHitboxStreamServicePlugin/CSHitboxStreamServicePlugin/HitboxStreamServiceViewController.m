//
//  HitboxStreamServiceViewController.m
//  CSHitboxStreamServicePlugin
//
//  Created by Zakk on 12/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "HitboxStreamServiceViewController.h"

@interface HitboxStreamServiceViewController ()

@end

@implementation HitboxStreamServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction)loginClicked:(id)sender
{
    [self.loginProgressIndicator startAnimation:nil];
    
    [self commitEditing];
    
    [self.serviceObj authenticate:self.serviceObj.authUsername password:self.password onComplete:^{
        BOOL failHidden;
        if (!self.serviceObj.authKey)
        {
            failHidden = NO;
        } else {
            failHidden = YES;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.loginProgressIndicator stopAnimation:nil];
            [self.loginFailedText setHidden:failHidden];
        });
        
        if (self.serviceObj.authKey)
        {
            [self.serviceObj fetchIngestServers:nil];
        }
    }];
}


@end
