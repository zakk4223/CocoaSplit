//
//  NSValueJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 6/19/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


@protocol NSValueJSExport <JSExport>

-(NSSize)sizeValue;
+(NSValue *)valueWithSize:(NSSize)size;
+(NSValue *)valueWithPoint:(NSPoint)point;


@end

@protocol NSConcreteValueJSExport <JSExport>

-(NSSize)sizeValue;

@end

JSEXPORT_PROTO(NSValueJSExport)
JSEXPORT_PROTO(NSConcreteValueJSExport)

