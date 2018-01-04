//
//  CSViewController.m
//  CocoaSplit
//
//  Created by Zakk on 1/3/18.


#import "CSViewController.h"

@interface CSViewController ()

@end

@implementation CSViewController


-(void)awakeFromNib
{
    [super awakeFromNib];
    
    if (self.parentView && (self.view.superview != self.parentView))
    {
        self.view.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.parentView addSubview:self.view];
        NSDictionary *views = @{@"subView": self.view};
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[subView]|" options:0 metrics:0 views:views];
        [self.parentView addConstraints:constraints];
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[subView]|" options:0 metrics:0 views:views];
        [self.parentView addConstraints:constraints];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
