//
//  CSAnimationChooserViewController.m
//  CocoaSplit
//
//  Created by Zakk on 3/26/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSAnimationChooserViewController.h"

@interface CSAnimationChooserViewController ()

@end

@implementation CSAnimationChooserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadAnimations];
    
    // Do view setup here.
}


- (IBAction)addButtonClicked:(id)sender
{
    
    
    [self commitEditing];
    
    NSLog(@"SELECTED %@", self.selectedAnimations);
    
    if (self.sourceLayout)
    {
        
        NSArray *animations = [self.animationList objectsAtIndexes:self.selectedAnimations];
        NSLog(@"ANIMATIONS %@", animations);
        
        for (id anim in animations)
        {
            [self.sourceLayout addAnimation:anim];
        }
    }
    NSLog(@"CLOSING POPOVER!");
    
    [self.popover close];
    
    
}


-(void)insertObject:(NSDictionary *)object inAnimationListAtIndex:(NSUInteger)index
{
    [self.animationList insertObject:object atIndex:index];
}


-(void)popoverDidClose:(NSNotification *)notification
{
    self.popover.contentViewController = nil;
}

-(void)loadAnimations
{
    CSAnimationRunnerObj *runner = [CaptureController sharedAnimationObj];
    NSDictionary *animations = [runner allAnimations];
    NSMutableArray *tmpList  = [NSMutableArray array];
    
    for (NSString *key in animations)
    {
        [tmpList addObject:animations[key]];
        
    }
    
    self.animationList = tmpList;
}


@end
