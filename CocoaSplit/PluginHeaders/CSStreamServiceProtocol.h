//
//  CSStreamServiceProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 8/29/14.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "CSOutputWriterProtocol.h"

@protocol CSStreamServiceProtocol <NSObject, NSCoding, CSOutputWriterProtocol>

@property bool isReady;

-(NSViewController  *)getConfigurationView;
-(NSString *)getServiceDestination;
-(NSString *)getServiceFormat;
+(NSString *)label;
+(NSString *)serviceDescription;
+(NSImage *)serviceImage;

-(void)prepareForStreamStart;



@end
