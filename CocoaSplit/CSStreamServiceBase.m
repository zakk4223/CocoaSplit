//
//  CSStreamServiceBase.m
//  CocoaSplit
//
//  Created by Zakk on 1/20/18.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceBase.h"
#import "CSLavfOutput.h"

@implementation CSStreamServiceBase




-(NSViewController  *)getConfigurationView
{
    return nil;
}


-(NSString *)getServiceDestination
{
    return nil;
}


-(NSString *)getServiceFormat
{
    return nil;
}

+(NSString *)label
{
    return nil;
}


+(NSString *)serviceDescription
{
    return nil;
}

+(NSImage *)serviceImage
{
    return nil;
}

-(NSObject<CSOutputWriterProtocol> *)createOutput;
{
    return [[CSLavfOutput alloc] init];
}


-(void)prepareForStreamStart
{
    return;
}



- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    return;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    return [self init];
}


@synthesize isReady;

@end

