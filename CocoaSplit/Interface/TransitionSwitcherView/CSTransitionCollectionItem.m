//
//  CSTransitionCollectionItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/17/18.
//

#import "CSTransitionCollectionItem.h"

@interface CSTransitionCollectionItem ()

@end

@implementation CSTransitionCollectionItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)awakeFromNib
{
    NSLog(@"AWAKE %@", self);
}
-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    NSLog(@"REP %@", representedObject);
}
@end
