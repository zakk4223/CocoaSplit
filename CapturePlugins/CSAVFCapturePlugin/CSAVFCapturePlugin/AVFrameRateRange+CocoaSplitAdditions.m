//
//  AVFrameRateRange+CocoaSplitAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 1/19/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "AVFrameRateRange+CocoaSplitAdditions.h"

@implementation AVFrameRateRange (CocoaSplitAdditions)

- (NSString *)localizedName
{
	if ([self minFrameRate] != [self maxFrameRate]) {
		NSString *formatString = NSLocalizedString(@"FPS: %0.2f-%0.2f", @"FPS when minFrameRate != maxFrameRate");
		return [NSString stringWithFormat:formatString, [self minFrameRate], [self maxFrameRate]];
	}
	NSString *formatString = NSLocalizedString(@"FPS: %0.2f", @"FPS when minFrameRate == maxFrameRate");
	return [NSString stringWithFormat:formatString, [self minFrameRate]];
}


@end
