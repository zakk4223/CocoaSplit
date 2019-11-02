//
//  CSTimedOutputBuffer.m
//  CocoaSplit
//
//  Created by Zakk on 4/2/16.
//

#import "CSTimedOutputBuffer.h"
#import "AppDelegate.h"
@implementation CSTimedOutputBuffer



-(instancetype) init
{
    if (self = [super init])
    {
        _frameBuffer = [[NSMutableArray alloc] init];
        _name = @"Instant Recording";
        _current_file_index = 1;
    }
    return self;
}

-(instancetype) initWithCompressor:(id<VideoCompressor>)compressor
{
    if (self = [self init])
    {
        _compressor = compressor;
        [_compressor addOutput:self];
    }
    
    return self;
}


-(void)closeRemuxOutput:(AVFormatContext *)outputFormatCtx
{
    av_write_trailer(outputFormatCtx);
    if (!(outputFormatCtx->flags & AVFMT_NOFILE))
    {
        avio_closep(&outputFormatCtx->pb);
    }
    avformat_free_context(outputFormatCtx);
}



-(int)createRemuxOutputContext:(AVFormatContext **)outCtx forInputContext:(AVFormatContext *)inputCtx toFile:(NSString *)outputPath
{
    int avErr = 0;
    int videoStreamIndex = -1;
    
    avErr = avformat_alloc_output_context2(outCtx, NULL, NULL, outputPath.UTF8String);
    if (avErr < 0)
    {
        return avErr;
    }
    
    AVFormatContext *useOutCtx = *outCtx;
    
    avErr = 0;
    
    for (int i = 0; i < inputCtx->nb_streams; i++)
    {
        AVStream *ins = inputCtx->streams[i];
        AVCodecParameters *inpar = ins->codecpar;
        
        AVStream *outs = avformat_new_stream(useOutCtx, NULL);
        if (!outs)
        {
            avErr = -1;
            break;
        }
        avErr = avcodec_parameters_copy(outs->codecpar, inpar);
        if (avErr < 0)
        {
            break;
        }
        
        outs->codecpar->codec_tag = 0;
        if (inpar->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            videoStreamIndex = i;
        }
    }
    
    if (avErr < 0)
    {
        avformat_free_context(*outCtx);
        *outCtx = NULL;
        return avErr;
    }
    
    if (!(useOutCtx->flags & AVFMT_NOFILE))
    {
        avErr = avio_open(&useOutCtx->pb, outputPath.UTF8String, AVIO_FLAG_WRITE);
    }
    
    if (avErr >= 0)
    {
        avErr = avformat_write_header(useOutCtx, NULL);
    }
    
    if (avErr < 0)
    {
        avformat_free_context(*outCtx);
        *outCtx = NULL;
        return avErr;
    }
    return videoStreamIndex;
}


-(bool)remuxToFile:(NSString *)destFile sourceFiles:(NSArray *)sourceFiles startTime:(float)startTime endTime:(float)endTime
{
    
    int ret = 0;
    int64_t *ptsTimes = NULL;
    int64_t *dtsTimes = NULL;
    int64_t *ptsAdjusts = NULL;
    int64_t *dtsAdjusts = NULL;
    int64_t *ptsStarts = NULL;
    int64_t *dtsStarts = NULL;
    int64_t frameCnt = 0;
    
    int videoStreamIndex = 0;
    
    AVFormatContext *input_ctx = NULL;
    
    
    AVFormatContext *outputFormatCtx = NULL;
    
    int64_t start_pts = INT64_MAX;
    int64_t end_pts = INT64_MAX;
    


    NSUInteger idx = 0;
    
    for (NSString *path in sourceFiles)
    {
        ret = avformat_open_input(&input_ctx, path.UTF8String, NULL, NULL);
        if (ret < 0)
        {
            goto errLabel;
        }
        ret = avformat_find_stream_info(input_ctx, NULL);
        
        if (ret < 0)
        {
            goto errLabel;
        }
        
        if (idx == 0)
        {
            if (!outputFormatCtx)
            {
                videoStreamIndex = [self createRemuxOutputContext:&outputFormatCtx forInputContext:input_ctx toFile:destFile];
                if (videoStreamIndex < 0)
                {
                    goto errLabel;
                }
                
                AVStream *videoStream = input_ctx->streams[videoStreamIndex];
                if (startTime > 0.0f && videoStream)
                {
                    start_pts = av_rescale_q(startTime * AV_TIME_BASE, AV_TIME_BASE_Q, videoStream->time_base);
                    NSLog(@"GOING TO SEEK %lld", start_pts);

                    ret = av_seek_frame(input_ctx, videoStreamIndex, start_pts, AVSEEK_FLAG_BACKWARD);
                    if (ret < 0)
                    {
                        NSLog(@"Instant recording save: seek failed. Aborting");
                        goto errLabel;
                    }
                    
                }
                
                if (endTime > 0.0f && end_pts == INT64_MAX)
                {
                    end_pts = av_rescale_q(endTime * AV_TIME_BASE, AV_TIME_BASE_Q, videoStream->time_base);
                }
                
                ptsTimes = malloc(input_ctx->nb_streams*sizeof(int64_t));
                dtsTimes = malloc(input_ctx->nb_streams*sizeof(int64_t));
                memset(ptsTimes, 0, input_ctx->nb_streams*sizeof(int64_t));
                memset(dtsTimes, 0, input_ctx->nb_streams*sizeof(int64_t));
                
                ptsAdjusts = malloc(input_ctx->nb_streams*sizeof(int64_t));
                dtsAdjusts = malloc(input_ctx->nb_streams*sizeof(int64_t));
                memset(ptsAdjusts, 0, input_ctx->nb_streams*sizeof(int64_t));
                memset(dtsAdjusts, 0, input_ctx->nb_streams*sizeof(int64_t));
                ptsStarts = malloc(input_ctx->nb_streams*sizeof(int64_t));
                dtsStarts = malloc(input_ctx->nb_streams*sizeof(int64_t));
                
            }
            
        }
        

        memset(ptsStarts, 0, input_ctx->nb_streams*sizeof(int64_t));
        memset(dtsStarts, 0, input_ctx->nb_streams*sizeof(int64_t));
        NSLog(@"START LOOP FOR %@", path);
        while (1)
        {
            AVStream *ins = NULL;
            AVStream *outs = NULL;
            AVPacket pkt;
            

            
            
            ret = av_read_frame(input_ctx, &pkt);
            if (ret < 0)
            {
                break;
            }
            
            ins = input_ctx->streams[pkt.stream_index];
            outs = outputFormatCtx->streams[pkt.stream_index];
            
            if ((idx == sourceFiles.count-1) && (pkt.stream_index == videoStreamIndex) && (end_pts != INT64_MAX))
            {
                if (av_compare_ts(pkt.pts, ins->time_base, end_pts, ins->time_base) >= 0)
                {
                    break;
                }
            }
            
            
            if ((start_pts != INT64_MAX) && (idx == 0))
            {
                if (ptsStarts[pkt.stream_index] == 0)
                {
                    NSLog(@"PTS START %lld", pkt.pts);
                    ptsStarts[pkt.stream_index] = pkt.pts;
                }
                
                if (dtsStarts[pkt.stream_index] == 0)
                {
                    dtsStarts[pkt.stream_index] = pkt.dts;
                }
            }
            
            
            int64_t ptsAdj = ptsAdjusts[pkt.stream_index];
            int64_t dtsAdj = dtsAdjusts[pkt.stream_index];
            pkt.pts = av_rescale_q_rnd(pkt.pts - ptsStarts[pkt.stream_index], ins->time_base, outs->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);
            pkt.dts = av_rescale_q_rnd(pkt.dts - dtsStarts[pkt.stream_index], ins->time_base, outs->time_base, AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX);

            pkt.pts += ptsAdj;
            pkt.dts += dtsAdj;
            ptsTimes[pkt.stream_index] = pkt.pts;
            dtsTimes[pkt.stream_index] = pkt.dts;
            pkt.duration = av_rescale_q(pkt.duration, ins->time_base, outs->time_base);
            pkt.pos = -1;
            ret = av_interleaved_write_frame(outputFormatCtx, &pkt);
            frameCnt++;
            /*if (ret < 0)
            {
                NSLog(@"WRITE FRAME FAILED %@", path);
                break;
            }*/
            av_packet_unref(&pkt);
        }
        frameCnt = 0;
        if (ptsAdjusts)
        {
            memcpy(ptsAdjusts, ptsTimes, sizeof(int64_t)*input_ctx->nb_streams);
        }
        
        if (dtsAdjusts)
        {
            memcpy(dtsAdjusts, dtsTimes, sizeof(int64_t)*input_ctx->nb_streams);
        }
        
        avformat_close_input(&input_ctx);
        input_ctx = NULL;
        idx++;
        if (ptsAdjusts)
        {
            end_pts += ptsAdjusts[videoStreamIndex];
        }
    }
errLabel:
    if (ptsAdjusts)
        free(ptsAdjusts);
    if (dtsAdjusts)
        free(dtsAdjusts);
    if (ptsTimes)
        free(ptsTimes);
    if (dtsTimes)
        free(dtsTimes);
    if (ptsStarts)
        free(ptsStarts);
    if (dtsStarts)
        free(dtsStarts);
    [self closeRemuxOutput:outputFormatCtx];
    
    return ret >= 0;
}


-(void) writeCurrentBuffer:(NSString *)toFile withCompletionBlock:(void (^)(void))completionBlock
{
    [self writeCurrentBuffer:toFile usingDuration:self.bufferDuration withCompletionBlock:completionBlock];
}


-(void) writeCurrentBuffer:(NSString *)toFile usingDuration:(float)seconds_to_write withCompletionBlock:(void (^)(void))completionBlock
{
    
    NSMutableArray *muxInputs = [NSMutableArray array];
    

    if (!seconds_to_write)
    {
        seconds_to_write = self.bufferDuration;
    }
    
    
    float startTime = 0.0f;
    float endTime = 0.0f;
    
    float current_buffer_length = _currentBufferDuration;
    
    
    if ((seconds_to_write > current_buffer_length) && _previous_file_name)
    {
        [muxInputs addObject:_previous_file_name];
        startTime = current_buffer_length;
    } else if (current_buffer_length > seconds_to_write) {
        startTime = current_buffer_length - seconds_to_write;
    }
     
    
    [muxInputs addObject:_current_file_name];
    endTime = current_buffer_length;
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self remuxToFile:toFile sourceFiles:muxInputs startTime:startTime endTime:endTime];
        if (completionBlock)
        {
            completionBlock();
        }
        
    });
    return;
}


-(void) writeCurrentBuffer:(NSString *)toFile
{

    [self writeCurrentBuffer:toFile withCompletionBlock:nil];
}

-(void)stopBuffering
{
    if (_hlsOutput)
    {
        [_hlsOutput stopProcess];
        _hlsOutput = nil;
    }
}

-(void) buildOutputStream
{
    
    if (_hlsOutput)
    {
        [_hlsOutput stopProcess];
    }
    CaptureController *controller = [CaptureController sharedCaptureController];

    NSString *instantRecordDirectory = controller.instantRecordDirectory;
    
    _current_file_index = _current_file_index ^ 1;
    
    NSString *fileBase = [NSString stringWithFormat:@"LiveRecord-%d.mkv", _current_file_index];
    
    NSString *fileName = [NSString pathWithComponents:@[instantRecordDirectory, fileBase]];
    
    _previous_file_name = _current_file_name;
    _current_file_name = fileName;
    
    _hlsOutput = [[CSLavfOutput alloc] init];
    _hlsOutput.framerate = controller.captureFPS;
    _hlsOutput.stream_output = fileName;
    _hlsOutput.samplerate = controller.multiAudioEngine.sampleRate;
    _hlsOutput.audio_bitrate = controller.multiAudioEngine.audioBitrate;
    CAMultiAudioOutputTrack *audioTrack = controller.multiAudioEngine.defaultOutputTrack;
    
    _hlsOutput.activeAudioTracks = @{audioTrack.uuid: audioTrack}.mutableCopy;
    //_hlsOutput.privateOptions = @"movflags:frag_keyframe";
}

-(void) writeEncodedData:(CapturedFrameData *)frameData
{
    
    float frameDuration = CMTimeGetSeconds(frameData.videoDuration);

    
    
    if (!_hlsOutput || (_currentBufferDuration >= self.bufferDuration && frameData.isKeyFrame))
    {
        _currentBufferDuration = 0.0f;
        [self buildOutputStream];
        
    }
    
    [_hlsOutput queueFramedata:frameData];
    _currentBufferDuration  += frameDuration;
    return;
    
}

-(void)dealloc
{
    [self stopBuffering];
}

@end
