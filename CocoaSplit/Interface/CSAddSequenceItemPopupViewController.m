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
#import "CSSequenceItemAnimation.h"


@interface CSAddSequenceItemPopupViewController ()

@end

@implementation CSAddSequenceItemPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self adjustTableHeight:self.sequenceItemTypesTableView];
    
    // Do view setup here.
}

-(instancetype)init
{
    return [self initWithNibName:@"CSAddSequenceItemPopupViewController" bundle:nil];
}



-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}


-(void)adjustTableHeight:(NSTableView *)table
{
    
    
    NSSize vSize = self.view.frame.size;
    
    vSize.height = table.numberOfRows * table.rowHeight + 3;
    self.preferredContentSize = vSize;
    
    
}


-(NSArray *)sequenceItemTypes
{
    
    
    if (_sequenceItemTypes)
    {
        return _sequenceItemTypes;
    }
    

    NSMutableArray *ret = [NSMutableArray array];
    
    [ret addObject:[CSSequenceItemLayout class]];
    [ret addObject:[CSSequenceItemTransition class]];
    [ret addObject:[CSSequenceItemWait class]];
    [ret addObject:[CSSequenceItemAnimation class]];
    

    _sequenceItemTypes = ret;
    return ret;
}


- (IBAction)sequenceItemClicked:(id)sender
{
    
    Class clickedSequenceclass;
    clickedSequenceclass = [_sequenceItemTypes objectAtIndex:[self.sequenceItemTypesTableView rowForView:sender]];
    if (clickedSequenceclass && self.addSequenceItem)
    {
        self.addSequenceItem(clickedSequenceclass);
    }

}
@end
