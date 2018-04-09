//
//  CIFilter+BindableDescription.m
//  CocoaSplit
//
//  Created by Zakk on 4/9/18.
//

#import "CIFilter+BindableDescription.h"

@implementation CIFilter (BindableDescription)
-(NSString *)displayName
{
    return self.attributes[@"CIAttributeFilterDisplayName"];
}

@end
