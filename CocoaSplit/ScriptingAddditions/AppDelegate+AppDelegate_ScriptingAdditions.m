//
//  AppDelegate+AppDelegate_ScriptingAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "AppDelegate+AppDelegate_ScriptingAdditions.h"

@implementation AppDelegate (AppDelegate_ScriptingAdditions)

-(NSArray *)layouts
{
    return self.captureController.sourceLayouts;
}


- (unsigned int)countOfLayoutsArray {
    return (unsigned int)self.captureController.sourceLayouts.count;
}


-(void)setActivelayoutByString:(NSString *)byString
{
    NSUInteger selectedIdx = [self.captureController.sourceLayouts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((SourceLayout *)obj).name isEqualToString:byString];

    }];
    
    
    SourceLayout *selectedLayout = nil;
    
    if (selectedIdx != NSNotFound)
    {
        selectedLayout = [self.captureController.sourceLayouts objectAtIndex:selectedIdx];
    }
    
    
    if (selectedLayout)
    {
        [self setActiveLayout:selectedLayout];
    }
}


-(void)setActiveLayout:(SourceLayout *)layout
{
    self.captureController.selectedLayout = layout;
}


-(int)width
{
    return self.captureController.captureWidth;
}

-(int)height
{
    return self.captureController.captureHeight;
}

-(float)fps
{
    return self.captureController.captureFPS;
}

-(void)setFps:(double)fps
{
    self.captureController.captureFPS = fps;
}

-(SourceLayout *)activelayout
{
    return self.captureController.selectedLayout;
}


-(BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
    
    
    NSArray *keys = @[@"layouts", @"width", @"height", @"fps", @"activelayout"];
    
    return [keys containsObject:key];
}


@end
