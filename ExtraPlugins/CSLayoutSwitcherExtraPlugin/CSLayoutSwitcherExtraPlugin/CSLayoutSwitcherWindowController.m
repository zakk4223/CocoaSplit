//
//  CSLayoutSwitcherWindowController.m
//  CSLayoutSwitcherExtraPlugin
//
//  Created by Zakk on 9/5/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSLayoutSwitcherWindowController.h"
#import "CSLayoutSwitcher.h"


@implementation CSLayoutSwitcherWindowController




- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        
        
        
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(NSString *)layoutNames
{
    NSObject *myDelegate = [NSApp delegate];
    NSArray *layouts = [myDelegate valueForKey:@"layouts"];

    return [layouts valueForKey:@"name"];
    

}


- (IBAction)addSwitchEvent:(id)sender
{
    [self.window makeFirstResponder:nil];
    
    CSLayoutSwitchAction *newAction = [[CSLayoutSwitchAction alloc] init];
    newAction.active = YES;

    
    newAction.applicationString = self.applicationString;
    newAction.layoutName = self.layoutName;
    newAction.eventType = self.eventType;
    [self.switchActionsController addObject:newAction];
}

- (IBAction)deleteLayoutActions:(id)sender
{
    [self.switchActionsController removeObjectsAtArrangedObjectIndexes:self.switchActionsController.selectionIndexes];
}


@end
