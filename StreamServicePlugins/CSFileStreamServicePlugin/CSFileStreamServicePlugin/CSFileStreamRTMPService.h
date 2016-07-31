//
//  CSFileStreamRTMPService.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"

@interface CSFileStreamRTMPService : NSObject <CSStreamServiceProtocol>


@property bool isReady;
@property (strong) NSString *destinationURI;


-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;



@end
