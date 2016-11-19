//
//  CSAddOutputPopupViewController.m
//  CocoaSplit
//
//  Created by Zakk on 7/29/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAddOutputPopupViewController.h"
#import "CSStreamServiceProtocol.h"
#import "NSView+NSLayoutConstraintFilter.h"



@interface CSAddOutputPopupViewController ()

@end

@implementation CSAddOutputPopupViewController


-(instancetype)init
{
    return [self initWithNibName:@"CSAddOutputPopupViewController" bundle:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self adjustTableHeight:self.outputTypesTableView];
    // Do view setup here.
}



/*
-(void)switchToInitialView
{
    
    NSRect lRect = [self.outputTypesTableView rectOfRow:self.outputTypesTableView.numberOfRows - 1];
    
    
    NSRect vRect = self.outputTypesTableView.frame;
    NSSize newSize = NSMakeSize(vRect.size.width, lRect.origin.y+lRect.size.height+2);
    
    vRect.size = newSize;
    vRect.origin.y = self.view.frame.size.height/2 - newSize.height/2;
    [self.outputTypesTableView setFrame:vRect];
    [self.view.animator addSubview:self.initialView];
    self.popover.contentSize = newSize;
    [self.initialView setFrameOrigin:NSMakePoint(0,0)];

    
}
*/


-(void)adjustTableHeight:(NSTableView *)table
{
    

    NSSize vSize = self.view.frame.size;
    
    vSize.height = table.numberOfRows * table.rowHeight + 3;
    self.preferredContentSize = vSize;
    
    
}


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}


- (IBAction)inputTableButtonClicked:(id)sender
{
    
    Class clickedOutputclass;
    clickedOutputclass = [_outputTypes objectAtIndex:[self.outputTypesTableView rowForView:sender]];
    if (clickedOutputclass && self.addOutput)
    {
        self.addOutput(clickedOutputclass);
    }
    
}


-(NSArray *)outputTypes
{
    
    if (_outputTypes)
    {
        return _outputTypes;
    }
    
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] streamServicePlugins];
    
    NSArray *sortedKeys = [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    
    
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *key in sortedKeys)
    {
        Class streamClass = pluginMap[key];
        [ret addObject:streamClass];
    }
    
    _outputTypes = ret;
    return ret;
}


@end
