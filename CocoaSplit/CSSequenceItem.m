//
//  CSSequenceItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItem.h"
#import "CSSequenceItemViewController.h"

@implementation CSSequenceItem


-(instancetype)init
{
    if (self = [super init])
    {
        [self updateItemDescription];
    }
    
    return self;
}


+(NSImage *)image
{
    return nil;
}

+(NSString *)label
{
    return @"Sequence Item";
}


-(void)updateItemDescription
{
    self.itemDescription = @"Sequence Item";
}


-(NSString *)generateItemScript
{
    return nil;
}


-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)(void))completionBlock
{
    completionBlock();
}


-(CSSequenceItemViewController *)configurationView
{
    
    CSSequenceItemViewController *configViewController;
    
    NSString *controllerName = [NSString stringWithFormat:@"%@ViewController",     NSStringFromClass([self class])];
    
    
    
    
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        
        configViewController = [[viewClass alloc] init];
        
        if (configViewController)
        {
            NSLog(@"CONFIG VIEW C %@", configViewController);
            //Be gross like input view controllers!
            configViewController.sequenceItem = self;
        }
    }
    return configViewController;
    
}

@end
