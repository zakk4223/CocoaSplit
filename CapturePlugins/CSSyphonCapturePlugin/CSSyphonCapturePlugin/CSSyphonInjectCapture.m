//
//  CSSyphonInjectCapture.m
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//

#import "CSSyphonInjectCapture.h"

@implementation CSSyphonInjectCapture

@synthesize activeVideoDevice = _activeVideoDevice;


+(NSString *)label
{
    return @"SyphonInjectCapture";
}




-(bool) isSyphonInjectInstalled
{
    
    NSEnumerator *searchPathEnum;
    
    NSArray *scriptDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    
    searchPathEnum = [scriptDirs objectEnumerator];
    NSString *currPath;
    while(currPath = [searchPathEnum nextObject])
    {
        
        NSString *bundlePath = [currPath stringByAppendingPathComponent:@"ScriptingAdditions/SASyphonInjector.osax"];

        NSBundle *injectBundle = [NSBundle bundleWithPath:bundlePath];
        
        
        if (injectBundle)
        {
            NSString *bundleVersion = [[injectBundle infoDictionary] valueForKey:@"CFBundleVersion"];
            NSComparisonResult comp = [@"1.2" compare:bundleVersion options:NSNumericSearch];
            if (comp == NSOrderedSame || comp == NSOrderedAscending)
            {
                return YES;
            }
            
        }
    }
    
    return NO;

}


-(NSString *)configurationViewName
{
    if (![self isSyphonInjectInstalled])
    {
        return @"CSSyphonInjectCaptureViewNotInstalled";
    }
    
    return [super configurationViewName];
}


-(void)commonInit
{
    [super commonInit];
    [self changeApplicationList];
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(changeApplicationList) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(changeApplicationList) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
}



//Superclass calls this when a syphon notification arrives

-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    
    _activeVideoDevice = activeVideoDevice;
    [self changeAvailableVideoDevices];

    NSString *appExecutablePath = activeVideoDevice.uniqueID;
    NSRunningApplication *injectApp;


    
    NSArray *matchingApps = [[[NSWorkspace sharedWorkspace] runningApplications] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"activationPolicy = %@ AND executableURL.absoluteString = %@", @(NSApplicationActivationPolicyRegular), appExecutablePath]];
    
    
    if (matchingApps && matchingApps.count > 0)
    {
        injectApp = matchingApps.firstObject;
    }
    
    if (injectApp)
    {
        _syphonServer = nil;
        
        [self setSyphonServer];
        
        if (!_syphonServer)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self injectApp:injectApp];
            });
        }
    }
}


-(void)changeApplicationList
{
    
    NSArray *applications = [[[NSWorkspace sharedWorkspace] runningApplications] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"activationPolicy = %@", @(NSApplicationActivationPolicyRegular)]];
    
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    
    for(NSRunningApplication *app in applications)
    {
        CSAbstractCaptureDevice *newDev;
        
        newDev = [[CSAbstractCaptureDevice alloc] initWithName:app.localizedName device:nil uniqueID:app.executableURL.absoluteString];
        
        [retArr addObject:newDev];
        
        if (!self.activeVideoDevice && [newDev.uniqueID isEqualToString:self.savedUniqueID])
        {
            self.activeVideoDevice = newDev;
        }

    }
    
    self.availableVideoDevices = (NSArray *)retArr;
    
}


-(void)setSyphonServer
{
    if (!self.activeVideoDevice)
    {
        return;
    }

    NSString *selectedAppName = self.activeVideoDevice.captureName;
    
    
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    id sserv;
    
    for(sserv in servers)
    {
        NSString *syphonAppName = [sserv objectForKey:SyphonServerDescriptionAppNameKey];
        
        
        if ([syphonAppName isEqualToString:selectedAppName])
        {
            self.activeVideoDevice.captureDevice = sserv;
            [self startSyphon];
            break;
        }
    }

    
}

-(void)changeAvailableVideoDevices
{
    if (!self.activeVideoDevice)
    {
        return;
    }
    
    if(_syphonServer)
    {
        return;
    }
    [self setSyphonServer];
}


-(void)setBufferDimensions:(int)x_offset y_offset:(int)y_offset width:(int)width height:(int)height
{
    if (!self.injectSB)
    {
        return;
    }
    
    [self.injectSB sendEvent:'SASI' id:'ofst' parameters:'xofs', @(x_offset), 'yofs', @(y_offset),0];
    [self.injectSB sendEvent:'SASI' id:'reso' parameters:'wdth', @(width), 'hght', @(height),0];
}


-(void)changeBuffer
{
    if (!self.injectSB)
    {
        return;
    }
    
    [self.injectSB sendEvent:'SASI' id:'chbf' parameters:0];
}


-(void)toggleFast
{
    if (!self.injectSB)
    {
        return;
    }
    
    [self.injectSB sendEvent:'SASI' id:'fast' parameters:0];
}



-(void)injectApp:(NSRunningApplication *)toInject
{
    
    
    self.injectSB = [SBApplication applicationWithProcessIdentifier:toInject.processIdentifier];
    
    [self.injectSB setTimeout:10*60];
    
    [self.injectSB setSendMode:kAEWaitReply];
    [self.injectSB sendEvent:'ascr' id:'gdut' parameters:0];
    [self.injectSB setSendMode:kAENoReply];
    [self.injectSB sendEvent:'SASI' id:'injc' parameters:0];
}

-(void)dealloc
{
    [[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self];
}

@end
