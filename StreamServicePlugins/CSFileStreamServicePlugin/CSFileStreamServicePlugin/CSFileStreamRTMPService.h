//
//  CSFileStreamRTMPService.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"
#import "CSStreamServiceBase.h"

@interface CSFileStreamRTMPService : CSStreamServiceBase <CSStreamServiceProtocol>


@property bool isReady;
@property (strong) NSString *destinationURI;


-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;



@end
