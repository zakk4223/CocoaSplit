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

@synthesize actionType = _actionType;



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


-(NSArray *)targetNames
{
    if (self.actionType == kTransitionActivate || self.actionType == kTransitionDeactivate)
    {
        return self.transitionNames;
    } else {
        return self.layoutNames;
    }
    
    return @[];
}


-(void)setActionType:(layout_action)actionType
{
    _actionType = actionType;
    [self willChangeValueForKey:@"targetNames"];
    [self didChangeValueForKey:@"targetNames"];
}

-(layout_action)actionType
{
    return _actionType;
}


-(NSString *)layoutNames
{
    NSObject *myDelegate = [NSApp delegate];
    NSArray *layouts = [myDelegate valueForKey:@"layouts"];

    return [layouts valueForKey:@"name"];
    

}



-(NSArray *)transitionNames
{
    NSObject *myDelegate = [NSApp delegate];
    NSArray *transitions = [myDelegate valueForKey:@"transitions"];
    
    return [transitions valueForKey:@"name"];
}


- (IBAction)addSwitchEvent:(id)sender
{
    [self.window makeFirstResponder:nil];
    
    CSLayoutSwitchAction *newAction = [[CSLayoutSwitchAction alloc] init];
    newAction.active = YES;

    
    newAction.applicationString = self.applicationString;
    newAction.targetName = self.targetName;
    newAction.actionType = self.actionType;
    newAction.eventType = self.eventType;
    [self.switchActionsController addObject:newAction];
}

- (IBAction)deleteLayoutActions:(id)sender
{
    [self.switchActionsController removeObjectsAtArrangedObjectIndexes:self.switchActionsController.selectionIndexes];
}


@end
