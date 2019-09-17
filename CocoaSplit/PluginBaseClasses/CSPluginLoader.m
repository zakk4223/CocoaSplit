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
        self.principalClassNameMap = [[NSMutableDictionary alloc] init];
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
                                                             NSApplicationSupportDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
    
    
    searchPathEnum = [librarySearchPaths objectEnumerator];
    while(currPath = [searchPathEnum nextObject])
    {
        [bundleSearchPaths addObject:
         [currPath stringByAppendingPathComponent:@"CocoaSplit/Plugins"]];
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
    
    
    if (!toLoad || ![toLoad shouldLoad])
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
        if ([registerMap objectForKey:classLabel])
        {
            //The class already exists, so don't load it again
            didLoad = NO;
        } else {
            [registerMap setObject:toLoad forKey:classLabel];
            didLoad = YES;
        }

       // [self.allPlugins addObject:toLoad];
        
        
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
        if ([self validateAndRegisterPluginClass:pClass])
        {
            [self addToPluginTracker:pClass fromBundle:nil];
        }
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

-(void)makeBundleVersionMap
{
    NSMutableArray *bundlePaths = [NSMutableArray array];
    [bundlePaths addObjectsFromArray:[self bundlePaths:@"bundle"]];
    NSEnumerator *pathEnum = [bundlePaths objectEnumerator];
    NSString *currPath;
    NSString *mainVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];

    while (currPath = [pathEnum nextObject])
    {
        NSBundle *currBundle = [NSBundle bundleWithPath:currPath];
        if(currBundle)
        {
            
            NSString *currClassName = [currBundle bundleIdentifier];
            NSString *currVersion = [currBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *minVersion = [currBundle objectForInfoDictionaryKey:@"CSMinVersion"];
            NSString *maxVersion = [currBundle objectForInfoDictionaryKey:@"CSMaxVersion"];
            if (minVersion)
            {
                if ([mainVersion compare:minVersion options:NSNumericSearch] == NSOrderedAscending)
                {
                    continue;
                }
            }
            
            if (maxVersion)
            {
                if ([mainVersion compare:maxVersion options:NSNumericSearch] == NSOrderedDescending)
                {
                    continue;
                }
            }
            
            
            NSBundle *mappedBundle = [self.principalClassNameMap objectForKey:currClassName];
            if (!mappedBundle)
            {
                [self.principalClassNameMap setObject:currBundle forKey:currClassName];
            } else {
                NSString *mappedVersion = [mappedBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                if (mappedVersion)
                {
                    if ([mappedVersion compare:currVersion options:NSNumericSearch] == NSOrderedDescending)
                    {
                        [self.principalClassNameMap setObject:currBundle forKey:currClassName];
                    }
                }
            }
        }
    }
}

- (void)loadAllBundles
{
    NSMutableArray *instances;



    NSBundle *currBundle;
    Class currPrincipalClass;
    [self makeBundleVersionMap];

    if(!instances)
    {
        instances = [[NSMutableArray alloc] init];
    }
    
    for (NSString *bundleIdentifier in self.principalClassNameMap)
    {
        currBundle = self.principalClassNameMap[bundleIdentifier];
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
                        if ([self validateAndRegisterPluginClass:tryClass])
                        {
                            [self addToPluginTracker:tryClass fromBundle:currBundle];
                        }
                    }

                }
                
                tryClasses = [factoryClass streamServiceClasses];
                if (tryClasses)
                {
                    for(Class tryClass in tryClasses)
                    {
                        if ([self validateAndRegisterPluginClass:tryClass])
                        {
                            [self addToPluginTracker:tryClass fromBundle:currBundle];
                        }
                    }
                    
                }
                
                tryClasses = [factoryClass extraPluginClasses];
                if (tryClasses)
                {
                    for(Class tryClass in tryClasses)
                    {
                        if ([self validateAndRegisterPluginClass:tryClass])
                        {
                            [self addToPluginTracker:tryClass fromBundle:currBundle];
                        }

                    }
                    
                }


                
            } else {
                if ([self validateAndRegisterPluginClass:currPrincipalClass])
                {

                    [self addToPluginTracker:currPrincipalClass fromBundle:currBundle];
                }
                    

            }
            
            
        }
    }
    [self loadAllPythonPlugins];
}
@end
