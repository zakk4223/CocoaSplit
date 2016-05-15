//
//  CSAddInputViewController.m
//  CocoaSplit
//
//  Created by Zakk on 5/8/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSAddInputViewController.h"
#import "CSAddInputTypeViewController.h"
#import "NSView+NSLayoutConstraintFilter.h"
#import "CSCaptureSourceProtocol.h"
#import "CSPluginServices.h"
#import "AppDelegate.h"
#import "PreviewView.h"

@interface CSAddInputViewController ()

@end

@implementation CSAddInputViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self switchToInitialView];
    // Do view setup here.
}


-(void)switchToInputListView
{
    if (self.initialView && self.initialView.superview)
    {
        [self.initialView removeFromSuperview];
    }
    NSInteger height = [self adjustTableHeight:self.deviceTable];
    
    
    NSRect vFrame = self.inputListView.frame;
    //vFrame.size.height = height;
    
    
    [self.view addSubview:self.inputListView
     ];
    
    
    //[self.initialView setFrame:self.view.frame];
    
    self.popover.contentSize = self.inputListView.frame.size;
}


-(void)switchToInitialView
{
    if (self.inputListView && self.inputListView.superview)
    {
        [self.inputListView removeFromSuperview];
    }
    NSInteger height = [self adjustTableHeight:self.initialTable];
    
    NSLog(@"INITIAL FRAME %@ %@", NSStringFromRect(self.initialView.frame), NSStringFromRect(self.initialTable.frame));
    
    NSRect vFrame = self.initialView.frame;
    //vFrame.size.height = height;
    
    NSLog(@"VIEW %@", self.view);
    
    [self.view addSubview:self.initialView];
    
    
    //[self.initialView setFrame:self.view.frame];

    self.popover.contentSize = self.initialView.frame.size;

}



-(NSInteger)adjustTableHeight:(NSTableView *)table
{
    NSInteger height = 0;
    for (int i = 0; i < table.numberOfRows; i++)
    {
        NSView *view = [table viewAtColumn:0 row:i makeIfNecessary:YES];
        height += view.frame.size.height;
    }
    
    height+=4;
    
    NSScrollView *tSview = (NSScrollView *)table.superview.superview;

    NSLayoutConstraint *constraint = [tSview constraintForAttribute:NSLayoutAttributeHeight];
    [constraint setConstant:height];

//    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:tSview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:height];
//    [tSview addConstraint:constraint];
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
    
    AppDelegate *myAppDelegate = [[NSApplication sharedApplication] delegate];
        
    if (myAppDelegate.captureController)
    {
        [myAppDelegate.captureController.activePreviewView addInputSourceWithInput:toAdd];
    }
 
  }


-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    return NO;
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
