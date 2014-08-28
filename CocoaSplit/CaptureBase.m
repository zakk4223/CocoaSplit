//
//  CaptureBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CaptureBase.h"

@implementation CaptureBase

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.activeVideoDevice.uniqueID forKey:@"active_uniqueID"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
     
        self.savedUniqueID = [aDecoder decodeObjectForKey:@"active_uniqueID"];
        [self setDeviceForUniqueID:self.savedUniqueID];
    }
    
    return self;
}

-(NSView *)configurationView
{
    
    
    NSString *controllerName = [NSString stringWithFormat:@"%@ViewController", self.className];
    
    NSView *ret = nil;
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        self.configViewController = [[viewClass alloc] initWithNibName:controllerName bundle:nil];
        if (self.configViewController)
        {
            ret = self.configViewController.view;
            //Should probably make a base class for view controllers and put captureObj there
            //but for now be gross.
            [self.configViewController setValue:self forKey:@"captureObj"];
        }
    }
    return ret;
    
}


-(void)setDeviceForUniqueID:(NSString *)uniqueID
{
    AbstractCaptureDevice *dummydev = [[AbstractCaptureDevice alloc] init];
    
    dummydev.uniqueID = uniqueID;
    
    NSArray *currentAvailableDevices;
    
    currentAvailableDevices = self.availableVideoDevices;
    
    
    NSUInteger sidx;
    sidx = [currentAvailableDevices indexOfObject:dummydev];
    
    if (sidx == NSNotFound)
    {
        self.activeVideoDevice = nil;
    } else {
        
        self.activeVideoDevice = [currentAvailableDevices objectAtIndex:sidx];
    }
}

-(CVImageBufferRef) getCurrentFrame
{
    return NULL;
}



@end
