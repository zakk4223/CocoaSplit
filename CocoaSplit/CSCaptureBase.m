//
//  CaptureBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved
//

#import "CSCaptureBase.h"

@implementation CSCaptureBase

+(NSString *) label
{
    return NSStringFromClass(self);
}


-(instancetype) init
{
    if (self = [super init])
    {
        self.needsSourceSelection = YES;
    }
    
    return self;
}


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

-(NSViewController *)configurationView
{
    
    NSViewController *configViewController;
    
    NSString *controllerName = [NSString stringWithFormat:@"%@ViewController", self.className];
    
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        configViewController = [[viewClass alloc] initWithNibName:controllerName bundle:[NSBundle bundleForClass:self.class]];
        
        if (configViewController)
        {
            
            //Should probably make a base class for view controllers and put captureObj there
            //but for now be gross.
            [configViewController setValue:self forKey:@"captureObj"];
        }
    }
    return configViewController;
    
}


-(void)setDeviceForUniqueID:(NSString *)uniqueID
{
    CSAbstractCaptureDevice *dummydev = [[CSAbstractCaptureDevice alloc] init];
    
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

-(CIImage *) currentImage
{
    return nil;
}


-(CVImageBufferRef) getCurrentFrame
{
    return NULL;
}



@end
