//
//  CSYoutubeStreamServiceViewController.m
//  CSYoutubeStreamServicePlugin
//
//  Created by Zakk on 7/24/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSYoutubeStreamServiceViewController.h"
#import "CSPluginServices.h"

@interface CSYoutubeStreamServiceViewController ()

@end

@implementation CSYoutubeStreamServiceViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        // Initialization code here.
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)authenticateUser:(id)sender
{
    [self.serviceObj authenticateUser];
}


@end
