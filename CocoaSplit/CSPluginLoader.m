//
//  CSPluginLoader.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSPluginLoader.h"
#import "CSCaptureSourceProtocol.h"
#import "CSStreamServiceProtocol.h"
#import "CSPluginFactoryProtocol.h"
#import "CSExtraPluginProtocol.h"
#import "CaptureController.h"
#import <Foundation/NSObjCRuntime.h>

#import <objc/objc.h>
#import <objc/runtime.h>


@implementation CSPluginLoader

+(id) sharedPluginLoader
{
    static CSPluginLoader *sharedCSPluginLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        sharedCSPluginLoader = [[self alloc] init];
    });
    
    return sharedCSPluginLoader;
}

-(instancetype) init
{
    if (self = [super init])
    {
        self.sourcePlugins = [[NSMutableDictionary alloc] init];
        self.streamServicePlugins  = [[NSMutableDictionary alloc] init];
        self.extraPlugins  = [[NSMutableDictionary alloc] init];
        self.allPlugins = [NSMutableArray array];
        


    }
    
    return self;
}



- (NSMutableArray *)bundlePaths:(NSString *)withExtension
{
    NSArray *librarySearchPaths;
    NSEnumerator *searchPathEnum;
    NSString *currPath;
    NSMutableArray *bundleSearchPaths = [NSMutableArray array];
    NSMutableArray *allBundles = [NSMutableArray array];
    
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(
                                                             NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    
    searchPathEnum = [librarySearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        [bundleSearchPaths addObject:
         [currPath stringByAppendingPathComponent:@"Application Support/CocoaSplit/Plugins"]];
    }
    [bundleSearchPaths addObject:
     [[NSBundle mainBundle] builtInPlugInsPath]];
    
    searchPathEnum = [bundleSearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        NSDirectoryEnumerator *bundleEnum;
        NSString *currBundlePath;
        bundleEnum = [[NSFileManager defaultManager]
                      enumeratorAtPath:currPath];
        if(bundleEnum)
        {
            while(currBundlePath = [bundleEnum nextObject])
            {
                if([[currBundlePath pathExtension] isEqualToString:withExtension])
                {
                    [allBundles addObject:[currPath
                                           stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
    
    return allBundles;
}


-(void) loadPrivateAndUserImageUnits
{
    
    NSArray *IUPluginPaths = [self bundlePaths:@"plugin"];
    
    for (NSString *IUPath in IUPluginPaths)
    {
        
        NSURL *filterURL = [NSURL fileURLWithPath:IUPath];
        [CIPlugIn loadPlugIn:filterURL allowExecutableCode:YES];
    }
    
}



-(bool)validateAndRegisterPluginClass:(Class)toLoad
{
    if (!toLoad)
    {
        return NO;
    }
    
    
    bool didLoad = NO;
    
    NSString *classLabel = [toLoad label];
    NSMutableDictionary *registerMap = nil;
    
    
    
    if ([toLoad conformsToProtocol:@protocol(CSCaptureSourceProtocol)])
    {
        registerMap = self.sourcePlugins;
    } else if ([toLoad conformsToProtocol:@protocol(CSStreamServiceProtocol)]) {
        registerMap = self.streamServicePlugins;
    } else if ([toLoad conformsToProtocol:@protocol(CSExtraPluginProtocol)]) {
        registerMap = self.extraPlugins;
    }
    
    if (registerMap)
    {
        [registerMap setObject:toLoad forKey:classLabel];

       // [self.allPlugins addObject:toLoad];
        
        didLoad = YES;
    }
    
    return didLoad;
}





-(void)loadAllPythonPlugins
{
    CSAnimationRunnerObj *animObj = [CaptureController sharedAnimationObj];
    
    NSArray *pluginClasses  = nil;
    
    
    pluginClasses = [animObj allPlugins];
    for (Class pClass in pluginClasses)
    {
        [self addToPluginTracker:pClass fromBundle:nil];

        [self validateAndRegisterPluginClass:pClass];
    }
}


-(void)addToPluginTracker:(Class) toAdd fromBundle:(NSBundle *)fromBundle
{
    
    NSMutableDictionary *addMap = [NSMutableDictionary dictionary];
    addMap[@"label"] = [toAdd label];
    

    if (fromBundle)
    {
        NSString *version = [fromBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if (version)
        {
            addMap[@"version"] = version;
        }
        addMap[@"source"] = @"MacOS bundle";
        addMap[@"path"] = fromBundle.bundlePath;
        
    } else {
            addMap[@"source"] = @"Python file";
    }
    
    if ([toAdd conformsToProtocol:@protocol(CSCaptureSourceProtocol)])
    {
        
        addMap[@"plugin_type"] = @"Capture Source";
    } else if ([toAdd conformsToProtocol:@protocol(CSStreamServiceProtocol)]) {
        addMap[@"plugin_type"] = @"Streaming Service";
    } else if ([toAdd conformsToProtocol:@protocol(CSExtraPluginProtocol)]) {
        addMap[@"plugin_type"] = @"Extra";
    }

    [self.allPlugins addObject:addMap];
}


- (void)loadAllBundles
{
    NSMutableArray *instances;
    NSMutableArray *bundlePaths;
    NSEnumerator *pathEnum;
    NSString *currPath;
    NSBundle *currBundle;
    Class currPrincipalClass;
    
    bundlePaths = [NSMutableArray array];
    if(!instances)
    {
        instances = [[NSMutableArray alloc] init];
    }
    
    [bundlePaths addObjectsFromArray:[self bundlePaths:@"bundle"]];
    
    pathEnum = [bundlePaths objectEnumerator];
    while(currPath = [pathEnum nextObject])
    {
        currBundle = [NSBundle bundleWithPath:currPath];
        if(currBundle)
        {
            currPrincipalClass = [currBundle principalClass];

            if ([currPrincipalClass conformsToProtocol:@protocol(CSPluginFactoryProtocol)])
            {
                Class<CSPluginFactoryProtocol> factoryClass = currPrincipalClass;
                NSArray *tryClasses;
                
                tryClasses = [factoryClass captureSourceClasses];
                if (tryClasses)
                {
                    for(Class tryClass in tryClasses)
                    {
                        [self addToPluginTracker:tryClass fromBundle:currBundle];
                        [self validateAndRegisterPluginClass:tryClass];
                    }

                }
                
                tryClasses = [factoryClass streamServiceClasses];
                if (tryClasses)
                {
                    for(Class tryClass in tryClasses)
                    {
                        [self addToPluginTracker:tryClass fromBundle:currBundle];

                        [self validateAndRegisterPluginClass:tryClass];
                    }
                    
                }
                
                tryClasses = [factoryClass extraPluginClasses];
                if (tryClasses)
                {
                    for(Class tryClass in tryClasses)
                    {
                        [self addToPluginTracker:tryClass fromBundle:currBundle];

                        [self validateAndRegisterPluginClass:tryClass];
                    }
                    
                }


                
            } else {
                [self addToPluginTracker:currPrincipalClass fromBundle:currBundle];

                [self validateAndRegisterPluginClass:currPrincipalClass];
            }
            
            
        }
    }
    [self loadAllPythonPlugins];
}
@end
