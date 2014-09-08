//
//  PluginManagerWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 9/8/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSPluginLoader.h"


@interface PluginManagerWindowController : NSWindowController


@property (weak) CSPluginLoader *sharedPluginLoader;

@end
