//
//  CSLayoutCollectionItem.m
//  CocoaSplit
//
//  Created by Zakk on 10/4/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutCollectionItem.h"
#import "AppDelegate.h"
@interface CSLayoutCollectionItem ()

@end

@implementation CSLayoutCollectionItem


-(void) awakeFromNib
{
    [super awakeFromNib];
    AppDelegate *appDel = [NSApp delegate];
    
    self.captureController = appDel.captureController;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)layoutButtonPushed:(id)sender
{
    [self.captureController toggleLayout:self.representedObject];
}


-(void)saveToLayout:(id) sender
{
    [self.captureController saveToLayout:self.representedObject];
}


-(void)buildLayoutMenu
{
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    self.layoutMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    tmp = [self.layoutMenu insertItemWithTitle:@"Save To" action:@selector(saveToLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
}

-(void)showLayoutMenu:(NSEvent *)clickEvent
{
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildLayoutMenu];
    [self.layoutMenu popUpMenuPositioningItem:self.layoutMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}

@end
