//
//  CSChromaKeyPlugInLoader.h
//  CSChromaKey
//
//  Created by Zakk on 8/24/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <QuartzCore/CoreImage.h>

@interface CSChromaKeyPlugInLoader : NSObject <CIPlugInRegistration>

- (BOOL)load:(void *)host;

@end
