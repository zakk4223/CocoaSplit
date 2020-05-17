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
+(bool)shouldLoad;
-(NSObject<CSOutputWriterProtocol> *)createOutput;
-(NSObject<CSOutputWriterProtocol> *)createOutput:(NSString *)layoutName;


-(void)prepareForStreamStart;



@end
