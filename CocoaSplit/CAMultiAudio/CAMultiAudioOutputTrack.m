//
//  CAMultiAudioOutputTrack.m
//  CocoaSplit
//
//  Created by Zakk on 3/30/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import "CAMultiAudioOutputTrack.h"

@implementation CAMultiAudioOutputTrack

@synthesize name = _name;

-(void)setName:(NSString *)name
{
    _name = name;
    NSLog(@"NAME SET %@", name);
}

-(NSString *)name
{
    return _name;
}


-(instancetype) init
{
    if (self = [super init])
    {
        _uuid = [NSUUID UUID].UUIDString;
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_uuid forKey:@"uuid"];
    [aCoder encodeObject:_name forKey:@"name"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        _uuid = [aDecoder decodeObjectForKey:@"uuid"];
        _name = [aDecoder decodeObjectForKey:@"name"];
    }
    
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    CAMultiAudioOutputTrack *copy = [[CAMultiAudioOutputTrack alloc] init];
    copy.uuid = self.uuid;
    copy.name = self.name;
    copy.encoder = self.encoder;
    copy.encoderNode = self.encoderNode;
    copy.outputBus = self.outputBus;
    return copy;
}

@end
