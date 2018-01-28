//
//  CSCIFilterConfigProxy.h
//  CocoaSplit
//
//  Created by Zakk on 4/19/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface CSCIFilterConfigProxy : NSObject


@property (strong) CALayer *baseLayer;
@property (strong) NSString *layerFilterName;
@property (strong) NSMutableDictionary *baseDict;
@property (strong) NSString *filterType;

-(void)rebindViewControls:(NSView *)forView;


@end
