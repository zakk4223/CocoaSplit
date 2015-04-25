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
@synthesize selectedAnimations = _selectedAnimations;


- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadAnimations];
    
    // Do view setup here.
}


-(void)setSelectedAnimations:(NSIndexSet *)selectedAnimations
{
    _selectedAnimations = selectedAnimations;
    
    self.selectedAnimation = [self.animationList objectAtIndex:[selectedAnimations firstIndex]];
}

-(NSIndexSet *)selectedAnimations
{
    return _selectedAnimations;
}


- (IBAction)addButtonClicked:(id)sender
{
    
    
    [self commitEditing];
    
    
    if (self.sourceLayout)
    {
        
        NSArray *animations = [self.animationList objectsAtIndexes:self.selectedAnimations];
        
        for (id anim in animations)
        {
            [self.sourceLayout addAnimation:anim];
        }
    }
    
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
    NSString *animationPluginPath = [[NSBundle bundleForClass:self.class] pathForResource:@"CSAnimationRunner" ofType:@"plugin"];
    
    NSDictionary *animations = [runner allAnimations];
    NSMutableArray *tmpList  = [NSMutableArray array];
    
    for (NSString *key in animations)
    {
        [tmpList addObject:animations[key]];
        
    }
    
    self.animationList = tmpList;
}


@end
