//
//  CSPluginFactoryProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CSPluginFactoryProtocol <NSObject>

//This protocol just contains class methods used to load various plugin classes.
//Useful for plugins that want to implement multiple plugin types in one bundle.

+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;


@end
