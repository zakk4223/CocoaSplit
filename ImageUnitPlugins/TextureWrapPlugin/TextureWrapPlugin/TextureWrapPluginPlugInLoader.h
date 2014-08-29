//
//  TextureWrapPluginPlugInLoader.h
//  TextureWrapPlugin
//
//  Created by Zakk on 8/2/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <QuartzCore/CoreImage.h>

@interface TextureWrapPluginPlugInLoader : NSObject <CIPlugInRegistration>

- (BOOL)load:(void *)host;

@end
