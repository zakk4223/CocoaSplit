//
//  CSAddSequenceItemPopupViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSAddSequenceItemPopupViewController.h"
#import "CSSequenceItemLayout.h"
#import "CSSequenceItemTransition.h"
#import "CSSequenceItemWait.h"


@interface CSAddSequenceItemPopupViewController ()

@end

@implementation CSAddSequenceItemPopupViewController


- (IBAction)saveButtonClicked:(id)sender
{
    [_itemController commitEditing];
    if (self.addSequenceItem)
    {
        self.addSequenceItem(self.editItem);
    }
    self.editItem = nil;

}

- (IBAction)cancelButtonClicked:(id)sender
{
    [_itemController discardEditing];
    
    if (self.addSequenceItem)
    {
        self.addSequenceItem(nil);
    }
    self.editItem = nil;

}


-(instancetype)initWithSequenceItem:(CSSequenceItem *)item
{
    if (self = [self initWithNibName:@"CSAddSequenceItemPopupViewController" bundle:nil])
    {
        self.editItem = item;
    }
    
    return self;
}


-(void)loadView
{
    [super loadView];

    _itemController = [self.editItem configurationView];
    //self.mainView.subviews = @[];
    
    
    [self.itemConfigView addSubview:_itemController.view];
    [_itemController.view setFrameOrigin:NSMakePoint(0, self.itemConfigView.frame.size.height - _itemController.view.frame.size.height)];

}








@end
