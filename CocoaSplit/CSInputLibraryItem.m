//
//  CSInputLibraryItem.m
//  CocoaSplit
//
//  Created by Zakk on 10/18/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSInputLibraryItem.h"

@implementation CSInputLibraryItem



-(instancetype) init
{
    if (self = [super init])
    {
        self.inputImage = [NSImage imageNamed:NSImageNameUser];
    }
    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.inputImage forKey:@"inputImage"];
    [aCoder encodeObject:self.inputData forKey:@"inputData"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _inputData = [aDecoder decodeObjectForKey:@"inputData"];
        _inputImage = [aDecoder decodeObjectForKey:@"inputImage"];
    }
    
    return self;
}


-(id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:propertyList];
}

+(NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[@"cocoasplit.library.item"];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return @[@"cocoasplit.library.item"];
}

-(id)pasteboardPropertyListForType:(NSString *)type
{
    if (![type isEqualToString:@"cocoasplit.library.item"])
    {
        return nil;
    }
    
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}


@end
