//
//  CSTransitionSwitcherView.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionSwitcherView.h"
#import "CSTransitionCA.h"
@interface CSTransitionSwitcherView ()

@end

@implementation CSTransitionSwitcherView

- (void)viewDidLoad {
    CSTransitionCA *wtf = [[CSTransitionCA alloc] init];
    wtf.subType = kCATransitionFromRight;
    wtf.duration = @1.5f;
    [self.blah addObject:wtf];
    [super viewDidLoad];
    // Do view setup here.
}

-(void)awakeFromNib
{
    self.blah = [NSMutableArray array];

    [super awakeFromNib];

    
    [self.transitionsArrayController bind:@"contentArray" toObject:self.parentObjectController  withKeyPath:self.transitionArrayKeyPath options:nil];
    //[self.collectionView bind:@"content" toObject:self.parentObjectController withKeyPath:self.transitionArrayKeyPath options:nil];
}



- (IBAction)addTransitionClicked:(id)sender
{
    NSLog(@"TRANSITIONS %@", self.blah);
    CSTransitionCA *wtf = [[CSTransitionCA alloc] init];
    wtf.subType = kCATransitionFromRight;
    wtf.duration = @1.5f;
    [self.transitionsArrayController addObject:wtf];


    
}
@end
