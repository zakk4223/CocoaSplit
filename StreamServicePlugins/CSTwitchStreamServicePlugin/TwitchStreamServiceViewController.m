//
//  TwitchStreamServiceViewController.m
//  CSTwitchStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//

#import "TwitchStreamServiceViewController.h"


@interface TwitchStreamServiceViewController ()

@end

@implementation TwitchStreamServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        self.serverSortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
        
    }
    return self;
}




- (IBAction)doTwitchAuth:(id)sender
{
    
    [self.serviceObj authenticateUser];
     
}

- (IBAction)doTwitchstreamkey:(id)sender
{
    [self.serviceObj fetchTwitchStreamKey];

}


-(void)closeAuthWindow
{
    self.authWindow = nil;
}


-(void)receivedOAuth:(NSString *)oToken
{
    self.serviceObj.oAuthKey = oToken;
    [self.serviceObj fetchTwitchStreamKey];
    
}




@end
