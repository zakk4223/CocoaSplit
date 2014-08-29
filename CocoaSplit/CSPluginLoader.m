//
//  CSPluginLoader.m
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSPluginLoader.h"
#import "CSCaptureSourceProtocol.h"


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
        
    }
    
    return self;
}



- (NSMutableArray *)bundlePaths
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
                if([[currBundlePath pathExtension] isEqualToString:@"bundle"])
                {
                    [allBundles addObject:[currPath
                                           stringByAppendingPathComponent:currBundlePath]];
                }
            }
        }
    }
    
    return allBundles;
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
    
    [bundlePaths addObjectsFromArray:[self bundlePaths]];
    
    pathEnum = [bundlePaths objectEnumerator];
    while(currPath = [pathEnum nextObject])
    {
        currBundle = [NSBundle bundleWithPath:currPath];
        if(currBundle)
        {
            currPrincipalClass = [currBundle principalClass];
            if ([currPrincipalClass conformsToProtocol:@protocol(CSCaptureSourceProtocol)])
            {
                
                NSString *classLabel = [currPrincipalClass label];
                [self.sourcePlugins setObject:currPrincipalClass forKey:classLabel];
                
            }
        }
    }
}
@end
