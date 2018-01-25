//
//  CSStreamServiceBase.m
//  CocoaSplit
//
//  Created by Zakk on 1/20/18.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceProtocol.h"

@interface CSStreamServiceBase : NSObject <CSStreamServiceProtocol, NSCoding>

-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
-(NSString *)getServiceFormat;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;
-(NSObject<CSOutputWriterProtocol> *)createOutput;


@property (assign) bool isReady;
-(void)prepareForStreamStart;
@end



