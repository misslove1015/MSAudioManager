//
//  MSAudioService.m
//  MSAudioManager
//
//  Created by 郭明亮 on 2019/1/18.
//  Copyright © 2019 郭明亮. All rights reserved.
//

#import "MSAudioService.h"
#import "lame.h"

#define CUT_FIRST_PATH [NSString stringWithFormat:@"%@audioManager/cut1.m4a", NSTemporaryDirectory()]
#define CUT_SECOND_PATH [NSString stringWithFormat:@"%@audioManager/cut2.m4a", NSTemporaryDirectory()]
#define CUT_THIRD_PATH [NSString stringWithFormat:@"%@audioManager/cut3.m4a", NSTemporaryDirectory()]
#define MERGE_PATH [NSString stringWithFormat:@"%@audioManager/merge.m4a", NSTemporaryDirectory()]
#define WAV_TMP_PATH [NSString stringWithFormat:@"%@audioManager/wav_tmp.wav", NSTemporaryDirectory()]

@implementation MSAudioService

// 裁剪音频
+ (void)cutWithAudio:(NSString *)audioPath
           startTime:(CGFloat)startTime
             endTime:(CGFloat)endTime
          outputPath:(NSString *)outputPath
            complete:(void(^)(NSString *path))complete {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:videoAsset presetName:AVAssetExportPresetAppleM4A];
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    exportSession.timeRange = CMTimeRangeFromTimeToTime(CMTimeMake(startTime*100,100), CMTimeMake(endTime*100,100));
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if(AVAssetExportSessionStatusCompleted == exportSession.status) {
            NSLog(@"剪切成功！");
            if (complete) {
                complete(outputPath);
            }
        }else  {
            NSLog(@"Export Session Status: %ld", (long)exportSession.status);
            NSLog(@"剪切失败！%@", exportSession.error);
            if (complete) {
                complete(nil);
            }
        }
    }];
}

// 拼接文件
+ (void)joinWithAudio1:(NSString *)audio1
                audio2:(NSString *)audio2
            outputPath:(NSString *)outputPath
              complete:(void(^)(NSString *path))complete {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    
    AVURLAsset *audioAsset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audio1]];
    AVURLAsset *audioAsset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audio2]];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *audioTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    AVMutableCompositionTrack *audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    AVAssetTrack *audioAssetTrack1 = [[audioAsset1 tracksWithMediaType:AVMediaTypeAudio]firstObject];
    AVAssetTrack *audioAssetTrack2 = [[audioAsset2 tracksWithMediaType:AVMediaTypeAudio]firstObject];
    [audioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset1.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero error:nil];
    [audioTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset2.duration) ofTrack:audioAssetTrack2 atTime:audioAsset1.duration error:nil];
    AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = outputPath;
    if([[NSFileManager defaultManager]fileExistsAtPath:outPutFilePath]) {
        [[NSFileManager defaultManager]removeItemAtPath:outPutFilePath error:nil];
    }
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A;
    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^{
        
        if(session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并成功！");
            if (complete) {
                complete(outputPath);
            }
        }else {
            NSLog(@"Export Session Status: %ld", (long)session.status);
            NSLog(@"合并失败！%@", session.error);
            if (complete) {
                complete(nil);
            }
        }
    }];
}

// 替换音频
+ (void)replaceWithAudio:(NSString *)audioPath
             originAudio:(NSString *)originPath
                fromTime:(CGFloat)fromTime
                 endTime:(CGFloat)endTime
                complete:(void(^)(NSString *path))complete {
    // 移除上次的临时文件
    NSArray *pathArray = @[CUT_FIRST_PATH, CUT_SECOND_PATH, MERGE_PATH];
    [pathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:obj]) {
            [[NSFileManager defaultManager] removeItemAtPath:obj error:nil];
        }
    }];
    
    // 原音频长度
    __block AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:originPath] options:nil];
    __block CMTime audioDuration = audioAsset.duration;
    __block float originDurtaion = CMTimeGetSeconds(audioDuration);
    NSLog(@"原音频长度 %f", originDurtaion);
    
    // 替换音频的长度
    AVURLAsset *replaceAudioAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioPath] options:nil];
    CMTime replaceAudioDuration = replaceAudioAsset.duration;
    float replaceDuration = CMTimeGetSeconds(replaceAudioDuration);
    NSLog(@"替换音频长度 %f", replaceDuration);
    
    NSLog(@"开始时间%f 结束时间%f", fromTime, endTime);
    
    if (fromTime == 0 && endTime >= originDurtaion) {
        // 全部替换
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:originPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:originPath error:nil];
        }
        
        [self cutWithAudio:audioPath startTime:0 endTime:replaceDuration outputPath:originPath complete:^(NSString * _Nonnull path) {
            if (complete) {
                complete(path);
            };
        }];
        
    }else if (fromTime == 0 && endTime <= originDurtaion){
        // 替换前面一段
        [self cutWithAudio:originPath startTime:endTime endTime:originDurtaion outputPath:CUT_FIRST_PATH complete:^(NSString * _Nonnull path) {
            
            [self joinWithAudio1:audioPath audio2:CUT_FIRST_PATH outputPath:originPath complete:^(NSString * _Nonnull path) {
                if (complete) {
                    complete(path);
                }
            }];
        }];
        
    }else if (fromTime != 0 && endTime < originDurtaion) {
        // 替换中间一段
        // 从0裁剪到开始替换的位置，获得裁剪的第一部分
        [self cutWithAudio:originPath startTime:0 endTime:fromTime outputPath:CUT_FIRST_PATH complete:^(NSString * _Nonnull path) {
            
            // 从结束替换的位置裁剪到结尾，获得裁剪的第二部分
            [self cutWithAudio:originPath startTime:endTime endTime:originDurtaion outputPath:CUT_SECOND_PATH complete:^(NSString * _Nonnull path) {
                
                // 拼接裁剪的第一部分+替换的音频，获得合成的第一部分
                [self joinWithAudio1:CUT_FIRST_PATH audio2:audioPath outputPath:MERGE_PATH complete:^(NSString * _Nonnull path) {
                    
                    // 拼接合成的第一部分+裁剪的第二部分，获得最终音频
                    [self joinWithAudio1:MERGE_PATH audio2:CUT_SECOND_PATH outputPath:originPath complete:^(NSString * _Nonnull path) {
                        
                        if (complete) {
                            complete(path);
                        }
                        
                    }];
                }];
                
            }];
        }];
    }else {
        // 替换后面一段
        // 从0裁剪到开始替换的位置，获得裁剪的第一部分
        [self cutWithAudio:originPath startTime:0 endTime:fromTime outputPath:CUT_FIRST_PATH complete:^(NSString * _Nonnull path) {
            
            // 拼接裁剪的第一部分+替换的音频
            [self joinWithAudio1:CUT_FIRST_PATH audio2:audioPath outputPath:originPath complete:^(NSString * _Nonnull path) {
                
                if (complete) {
                    complete(originPath);
                };
                
            }];
        }];
    }
}

// 合并音频
- (void)mergeWithAudioArray:(NSArray<NSString *> *)audioArray
                 outputPath:(NSString *)outputPath
                   complete:(void(^)(NSString *path))complete {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    }
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    for (NSInteger i = 0; i < audioArray.count; i++) {
        AVURLAsset *audioAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audioArray[i]]];
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio]firstObject];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    
    NSString *outPutFilePath = outputPath;
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A;
    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^{
        
        if(session.status == AVAssetExportSessionStatusCompleted) {
            if (complete) {
                complete(outputPath);
            }
        }else {
            if (complete) {
                complete(nil);
            }
        }
    }];
}

// PCM 转码至 mp3
+ (void)pcmToMp3WithAudio:(NSString *)audioPath
               outputPath:(NSString *)outputPath
                 complete:(void(^)(NSString *path))complete {
    if(outputPath.length == 0) {
        if (complete) {
            complete(nil);
        }
        return;
    }
    // 输入路径
    NSString *inPath = audioPath;
    
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:audioPath]) {
        NSLog(@"文件不存在");
        return;
    }
    
    // 输出路径
    NSString *outPath = outputPath;
    
    @try {
        int read, write;
        
        FILE *pcm = fopen([inPath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([outPath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame, 2); // 声道：2
        lame_set_in_samplerate(lame, 44100); // 采样率：44100
        lame_set_VBR(lame, vbr_default);
        lame_set_brate(lame, 128); // 比特率：128K
        lame_set_mode(lame, 1);
        lame_set_quality(lame, 2); // 音频质量
        lame_init_params(lame);
        
        do {
            size_t size = (size_t)(2 * sizeof(short int));
            read = (int)fread(pcm_buffer, size, PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
        if (complete) {
            complete(nil);
        }
    }
    @finally {
        NSLog(@"MP3生成成功:%@", outputPath);
        if (complete) {
            complete(outputPath);
        }
    }
}

// m4a 转码至 mp3
+ (void)m4aToMp3WithAudio:(NSString *)audioPath
               outputPath:(NSString *)outputPath
                 complete:(void(^)(NSString *path))complete {
    
    [self m4aToWAVWithOriginalPath:audioPath outputPath:WAV_TMP_PATH complete:^(NSString *path) {
        if (path) {
            [self pcmToMp3WithAudio:path outputPath:outputPath complete:^(NSString * _Nonnull path) {
                if (complete) {
                    complete(path);
                }
            }];
        }else {
            if (complete) {
                complete(nil);
            }
        }
    }];
}

// m4a转WAV
+ (void)m4aToWAVWithOriginalPath:(NSString *)originalPath
                      outputPath:(NSString *)outputPath
                        complete:(void(^)(NSString *path))complete {
    NSURL *originalUrl = [NSURL fileURLWithPath:originalPath];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outputPath];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if (error) {
        NSLog(@"文件读取失败: %@", error);
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks audioSettings:nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    [assetReader addOutput:assetReaderOutput];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outPutUrl fileType:AVFileTypeCoreAudioFormat error:&error];
    
    if (error) {
        if (complete) {
            complete(nil);
        }
        return;
    }
    
    AudioChannelLayout channelLayout;
    
    memset(&channelLayout,0,sizeof(AudioChannelLayout));
    
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary*outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
     [NSNumber numberWithFloat:44100.0],AVSampleRateKey,
     [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)],AVChannelLayoutKey,
     [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
     [NSNumber numberWithBool:NO],AVLinearPCMIsNonInterleaved,
     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
     [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,nil];
    
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
    
    if([assetWriter canAddInput:assetWriterInput]) {
        
        [assetWriter addInput:assetWriterInput];
        
    }else{
        if (complete) {
            complete(nil);
        }
        return;
        
    }
    
    assetWriterInput.expectsMediaDataInRealTime=NO;
    [assetWriter startWriting];
    [assetReader startReading];
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake(0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue",NULL);    
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue usingBlock: ^{
        
        while(assetWriterInput.readyForMoreMediaData) {
            
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
            
            if(nextBuffer) {
                
                // append buffer
                
                [assetWriterInput appendSampleBuffer: nextBuffer];
                
                convertedByteCount += CMSampleBufferGetTotalSampleSize(nextBuffer);
                
            }else{
                
                [assetWriterInput markAsFinished];
                
                [assetWriter finishWritingWithCompletionHandler:^{
                    if (complete) {
                        complete(outputPath);
                    }
                }];
                
                [assetReader cancelReading];
                
                break;
                
            }
            
        }
        
    }];
}

// 获取音频音量信息
+ (void)getVoiceDataWithAudio:(NSString *)audioPath
                  sampleCount:(NSInteger)sampleCount
                       height:(CGFloat)height
                     complete:(void(^)(NSArray<NSNumber *> *voiceArray))complete {
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    NSString *voice = @"voice";
    [asset loadValuesAsynchronouslyForKeys:@[voice] completionHandler:^{
        int status = [asset statusOfValueForKey:voice error:nil];
        NSData *sampleData;
        if (status == AVKeyValueStatusLoaded) {
            sampleData = [self readAudioSamplesFromAsset:asset];
            if (sampleData) {
                NSArray *voiceArray = [self getVoiceFromData:sampleData sampleCount:sampleCount height:height];
                if (complete) {
                    complete(voiceArray);
                }
            }else{
                NSLog(@"文件读取失败");
                if (complete) {
                    complete(nil);
                }
            }
        }
    }];
}

// 从文件数据中获取音量
+ (NSArray *)getVoiceFromData:(NSData *)data sampleCount:(NSInteger)sampleCount height:(CGFloat)height {
    NSMutableArray *filteredSamples = [[NSMutableArray alloc]init];
    NSInteger samplesCount = data.length / sizeof(SInt16);
    NSInteger binSize = samplesCount / sampleCount;
    SInt16 *bytes = (SInt16 *)data.bytes;
    SInt16 maxSample = 0;
    // sint16两个字节的空间
    // 以binSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    for (NSUInteger i = 0; i < samplesCount; i += binSize) {
        // 在sampleCount（所有数据）个数据中抽样，抽样方法为在binSize个数据为一个样本，在样本中选取一个数据
        
        SInt16 sampleBin [binSize];
        for (NSUInteger j = 0; j < binSize; j++) {
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
        }
        // 选取样本数据中最大的一个数据
        SInt16 value = [self maxValueInArray:sampleBin ofSize:binSize];
        // 保存数据
        [filteredSamples addObject:@(value)];
        // 将所有数据中的最大数据保存，作为一个参考，可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            maxSample = value;
        }
    }
    
    CGFloat scaleFactor = height / 1.5 / maxSample;
    for (NSUInteger i = 0; i < filteredSamples.count; i++) {
        filteredSamples[i] = @([filteredSamples[i] integerValue] * scaleFactor);
    }
    return filteredSamples;
}

// 返回区间内最大值
+ (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    SInt16 maxvalue = 0;
    for (int i = 0; i < size; i++) {
        if (abs(values[i] > maxvalue)) {
            maxvalue = abs(values[i]);
        }
    }
    return maxvalue;
}

// 读取文件数据
+ (NSData *)readAudioSamplesFromAsset:(AVAsset *)asset{
    NSError *error;
    AVAssetReader *assetReader = [[AVAssetReader alloc]initWithAsset:asset error:&error];
    if (error) {
        return nil;
    }
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!track) {
        return nil;
    }
    
    NSDictionary *dic = @{AVFormatIDKey:@(kAudioFormatLinearPCM),
                          AVLinearPCMIsBigEndianKey:@(NO),
                          AVLinearPCMIsFloatKey:@(NO),
                          AVLinearPCMBitDepthKey:@(16)};
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    [assetReader addOutput:output];
    [assetReader startReading];
    
    NSMutableData *sampleData = [[NSMutableData alloc]init];
    while (assetReader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer) {
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes);
            [sampleData appendBytes:sampleBytes length:length];
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
        }
    }
    
    if (assetReader.status == AVAssetReaderStatusCompleted) {
        return sampleData;
    }
    
    return nil;
}

// 寻找音频从何时开始有声音
+ (void)findBeginWithAudioPath:(NSString *)audioPath
                     startTime:(CGFloat)startTime
                         voice:(CGFloat)voice
                      complete:(void(^)(CGFloat time))complete {
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioPath]];
    CGFloat totalTime = CMTimeGetSeconds(asset.duration);
    NSString *begin = @"begin";
    [asset loadValuesAsynchronouslyForKeys:@[begin] completionHandler:^{
        int status = [asset statusOfValueForKey:begin error:nil];
        NSData *sampleData;
        if (status == AVKeyValueStatusLoaded) {
            sampleData = [self readAudioSamplesFromAsset:asset];
            if (sampleData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSInteger samplesCount = sampleData.length / sizeof(SInt16);
                    SInt16 *bytes = (SInt16 *)sampleData.bytes;
                    NSInteger startIndex = startTime/totalTime*samplesCount;
                    NSInteger index = 0;
                    for (NSInteger i = startIndex; i < samplesCount; i++) {
                        SInt16 value = CFSwapInt16LittleToHost(bytes[i]);
                        if (labs(value) > voice) {
                            index = i;
                            break;
                        }
                    }
                    
                    CGFloat beginTime = index/(CGFloat)samplesCount*totalTime;
                    if (complete) {
                        complete(beginTime);
                    }
                });
            }else{
                NSLog(@"文件读取失败");
                if (complete) {
                    complete(0);
                }
            }
        }
    }];
}

@end
