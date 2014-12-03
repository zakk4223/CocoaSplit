//
//  CSStreamServiceProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@protocol CSStreamServiceProtocol <NSObject>

@property bool isReady;

-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;


@end
