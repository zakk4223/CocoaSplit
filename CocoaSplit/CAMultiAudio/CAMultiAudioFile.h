//
//  CAMultiAudioFile.h
//  CocoaSplit
//
//  Created by Zakk on 7/23/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@interface CAMultiAudioFile : CAMultiAudioNode
{
    AudioFileID _audioFile;
    
}

@property (strong) NSString *filePath;
@property (assign) AudioStreamBasicDescription *outputFormat;
@property (weak) id converterNode;

-(instancetype)initWithPath:(NSString *)path;
-(void)play;
-(void)stop;

@end
