//
//  CSLayoutLayoutTransitionViewController.m
//  CocoaSplit
//
//  Created by Zakk on 8/17/17.
//

#import "CSLayoutLayoutTransitionViewController.h"
#import "CaptureController.h"
#import "CSCIFilterLayoutTransitionViewController.h"
#import "CSSimpleLayoutTransitionViewController.h"
#import "CaptureController.h"


@interface CSLayoutLayoutTransitionViewController ()

@end



@implementation CSLayoutLayoutTransitionViewController

-(instancetype) init
{
    if ([self initWithNibName:@"CSLayoutLayoutTransitionViewController" bundle:nil])
    {
        self.sourceLayouts = [CaptureController sharedCaptureController].sourceLayouts;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

}

 
@end
