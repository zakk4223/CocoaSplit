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



-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    [self.representedObject addObserver:self forKeyPath:@"in_live" options:NSKeyValueObservingOptionNew context:NULL];
    [self.representedObject addObserver:self forKeyPath:@"in_staging" options:NSKeyValueObservingOptionNew context:NULL];
}


-(void) awakeFromNib
{
    [super awakeFromNib];
    AppDelegate *appDel = [NSApp delegate];
    
    self.captureController = appDel.captureController;
    

}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    [self.layoutButton setNeedsDisplay];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)layoutButtonPushed:(id)sender
{
    if ([NSEvent modifierFlags] & NSCommandKeyMask)
    {
        [self.captureController switchToLayout:self.representedObject];
    } else {
        [self.captureController toggleLayout:self.representedObject];
    }
}


-(void)saveToLayout:(id) sender
{
    [self.captureController saveToLayout:self.representedObject];
}


-(void)deleteLayout:(id) sender
{
    SourceLayout *toDelete = self.representedObject;
    
    if ([self.captureController deleteLayout:self.representedObject])
    {
        [toDelete removeObserver:self forKeyPath:@"in_live"];
        [toDelete removeObserver:self forKeyPath:@"in_staging"];

    }
}


-(void)buildLayoutMenu
{
    NSInteger idx = 0;
    
    NSMenuItem *tmp;
    self.layoutMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    tmp = [self.layoutMenu insertItemWithTitle:@"Save To" action:@selector(saveToLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
    tmp = [self.layoutMenu insertItemWithTitle:@"Delete" action:@selector(deleteLayout:) keyEquivalent:@"" atIndex:idx++];
    tmp.target = self;
}

-(void)showLayoutMenu:(NSEvent *)clickEvent
{
    NSPoint tmp = [self.view convertPoint:clickEvent.locationInWindow fromView:nil];
    [self buildLayoutMenu];
    [self.layoutMenu popUpMenuPositioningItem:self.layoutMenu.itemArray.firstObject atLocation:tmp inView:self.view];
}

@end
