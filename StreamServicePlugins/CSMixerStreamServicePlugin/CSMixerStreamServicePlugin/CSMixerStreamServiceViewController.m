//
//  CSMixerStreamServiceViewController.m
//  CSMixerStreamServicePlugin
//
//  Created by Zakk on 4/13/18.
//

#import "CSMixerStreamServiceViewController.h"

@interface CSMixerStreamServiceViewController ()

@end

@implementation CSMixerStreamServiceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


-(IBAction)doMixerAuth:(id)sender
{
    [self.serviceObj authenticateUser];
}

- (IBAction)doStreamkey:(id)sender
{
    [self.serviceObj fetchStreamKey];
    
}
@end
