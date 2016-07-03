//
//  CSAddInputViewController.m
//  CocoaSplit
//
//  Created by Zakk on 5/8/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAddInputViewController.h"
#import "NSView+NSLayoutConstraintFilter.h"
#import "CSCaptureSourceProtocol.h"
#import "CSPluginServices.h"
#import "AppDelegate.h"
#import "PreviewView.h"

@interface CSAddInputViewController ()

@end

@implementation CSAddInputViewController



-(instancetype)init
{
    return [self initWithNibName:@"CSAddInputViewController" bundle:nil];
}


-(void)loadView
{
    
    [super loadView];
    [self switchToInitialView];
}


-(void)switchToInputListView
{
    
    NSSize __block newSize;
    
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    self.view.animations = @{@"subviews": transition};
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        if (self.initialView && self.initialView.superview)
        {
            [self.initialView.animator removeFromSuperview];
        }
        NSRect lRect = [self.deviceTable rectOfRow:self.deviceTable.numberOfRows - 1];
        
        
        NSRect vRect = self.inputListView.frame;
        newSize = NSMakeSize(vRect.size.width, lRect.origin.y+lRect.size.height+2+self.headerView.frame.size.height);
        
        vRect.size = newSize;
        vRect.origin.y = self.view.frame.size.height/2 - newSize.height/2;
        
        [self.inputListView setFrame:vRect];
        
        [self.view.animator addSubview:self.inputListView];
        
        
    } completionHandler:^{
        
        self.popover.contentSize = newSize;
        [self.inputListView setFrameOrigin:NSMakePoint(0,0)];
    }];
}


-(void)switchToInitialView
{
    NSSize __block newSize;
    
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    self.view.animations = @{@"subviews": transition};
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        if (self.inputListView && self.inputListView.superview)
        {
            [self.inputListView.animator removeFromSuperview];
        }
        NSRect lRect = [self.initialTable rectOfRow:self.initialTable.numberOfRows - 1];
        
        
        NSRect vRect = self.initialView.frame;
        newSize = NSMakeSize(vRect.size.width, lRect.origin.y+lRect.size.height+2);
        
        vRect.size = newSize;
        vRect.origin.y = self.view.frame.size.height/2 - newSize.height/2;
        [self.initialView setFrame:vRect];
        [self.view.animator addSubview:self.initialView];
        
        
    } completionHandler:^{
        self.popover.contentSize = newSize;
        [self.initialView setFrameOrigin:NSMakePoint(0,0)];
    }];
}



-(NSInteger)adjustTableHeight:(NSTableView *)table
{
    NSInteger height = 0;
    for (int i = 0; i < table.numberOfRows; i++)
    {
        NSView *view = [table viewAtColumn:0 row:i makeIfNecessary:YES];
        height += view.frame.size.height;
    }
    
    height += 4;
    
    
    NSScrollView *tSview = (NSScrollView *)table.superview.superview;

    NSLayoutConstraint *constraint = [tSview constraintForAttribute:NSLayoutAttributeHeight];
    [constraint setConstant:height];

    return height;
}


- (IBAction)nextViewButton:(id)sender
{
    [self.initialView removeFromSuperview];
    self.popover.contentSize = self.inputListView.frame.size;
    [self.view addSubview:self.inputListView];
}

- (IBAction)previousViewButton:(id)sender
{
    [self switchToInitialView];
    self.selectedInput = nil;
}

- (IBAction)initalTableButtonClicked:(id)sender
{
    
    NSObject <CSCaptureSourceProtocol> *clickedCapture;

    clickedCapture = [ self.sourceTypes objectAtIndex:[self.initialTable rowForView:sender]];
    
    if (!clickedCapture.availableVideoDevices || clickedCapture.availableVideoDevices.count == 0)
    {
        InputSource *newSrc = [[InputSource alloc] init];
        newSrc.selectedVideoType = clickedCapture.label;
        [self addInput:newSrc];        
    } else {
        self.selectedInput = clickedCapture;
        [self switchToInputListView];
    }
}

- (IBAction)inputTableButtonClicked:(id)sender
{
    CSAbstractCaptureDevice *clickedDevice;
    clickedDevice = [self.selectedInput.availableVideoDevices objectAtIndex:[self.deviceTable rowForView:sender]];
    if (clickedDevice)
    {
        InputSource *newSrc =  [[InputSource alloc] init];
        newSrc.selectedVideoType = self.selectedInput.label;
        newSrc.videoInput.activeVideoDevice = clickedDevice;
        [self addInput:newSrc];
    }
    
}

-(void)addInput:(id)toAdd
{
    
    
    if (self.previewView)
    {
        [self.previewView addInputSourceWithInput:toAdd];
    }
 
  }


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
}


-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.deviceTable)
    {
        return [tableView makeViewWithIdentifier:@"deviceTableView" owner:self];
    } else if (tableView == self.initialTable) {
        
        NSObject <CSCaptureSourceProtocol> *item = [self.sourceTypesController.arrangedObjects objectAtIndex:row];
        if (item.availableVideoDevices && item.availableVideoDevices.count > 0)
        {
            return [tableView makeViewWithIdentifier:@"initialInputView" owner:self];
        } else {
            return [tableView makeViewWithIdentifier:@"initialInputViewNoArrow" owner:self];
        }
    }
    
    return nil;
}


-(NSArray *)sourceTypes
{
    
    if (_sourceTypeList)
    {
        return _sourceTypeList;
    }
    
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
    
    NSArray *sortedKeys = [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSString *key in sortedKeys)
    {
        Class captureClass = pluginMap[key];
        NSObject <CSCaptureSourceProtocol> *newCaptureSession;
        
        newCaptureSession = [[captureClass alloc] init];

        [ret addObject:newCaptureSession];
    }
    
    _sourceTypeList = ret;
    return ret;
}


@end
