//
//  CSStreamServiceProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/29/14.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "CSOutputWriterProtocol.h"

@protocol CSStreamServiceProtocol <NSObject, NSCoding>

@property (assign) bool isReady;

-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
-(NSString *)getServiceFormat;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;
-(NSObject<CSOutputWriterProtocol> *)createOutput;

-(void)prepareForStreamStart;



@end
