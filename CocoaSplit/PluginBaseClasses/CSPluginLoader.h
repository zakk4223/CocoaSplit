//
//  CSPluginLoader.h
//  CocoaSplit
//
//  Created by Zakk on 8/28/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSPluginLoader : NSObject


@property (strong) NSMutableDictionary *sourcePlugins;
@property (strong) NSMutableDictionary *streamServicePlugins;
@property (strong) NSMutableDictionary *extraPlugins;
@property (strong) NSMutableArray *allPlugins;


+(id)sharedPluginLoader;
-(void)loadAllBundles;
-(void) loadPrivateAndUserImageUnits;


@end
