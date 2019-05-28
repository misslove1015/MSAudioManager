//
//  MSAudioService.h
//  MSAudioManager
//
//  Created by 郭明亮 on 2019/1/18.
//  Copyright © 2019 郭明亮. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MSAudioService : NSObject

/**
 裁剪音频

 @param audioPath 音频地址
 @param startTime 裁剪开始时间
 @param endTime 裁剪结束时间
 @param outputPath 输出路径
 @param complete 完成回调
 */
+ (void)cutWithAudio:(NSString *)audioPath
           startTime:(CGFloat)startTime
             endTime:(CGFloat)endTime
          outputPath:(NSString *)outputPath
            complete:(void(^)(NSString *path))complete;


/**
 拼接音频，将一个音频拼接在另一个音频的后面

 @param audio1 音频1，拼接后在前面
 @param audio2 音频2，拼接后在后面
 @param outputPath 输出路径
 @param complete 完成回调
 */
+ (void)joinWithAudio1:(NSString *)audio1
                audio2:(NSString *)audio2
            outputPath:(NSString *)outputPath
              complete:(void(^)(NSString *path))complete;



/**
 替换音频，本质为先剪切再拼接

 @param audioPath 替换的音频
 @param originPath 原音频
 @param fromTime 替换开始时间
 @param endTime 替换结束时间
 @param complete 完成回调
 */
+ (void)replaceWithAudio:(NSString *)audioPath
             originAudio:(NSString *)originPath
                fromTime:(CGFloat)fromTime
                 endTime:(CGFloat)endTime
                complete:(void(^)(NSString *path))complete;


/**
 合并音频，将多个音频头部对齐合并在一起

 @param audioArray 音频地址数组
 @param outputPath 输出路径
 @param complete 完成回调
 */
- (void)mergeWithAudioArray:(NSArray<NSString *> *)audioArray
                 outputPath:(NSString *)outputPath
                   complete:(void(^)(NSString *path))complete;




/**
 PCM(wav、caf) 转码至 mp3

 @param audioPath 需要转码的音频
 @param outputPath 输出路径
 @param complete 完成回调
 */
+ (void)pcmToMp3WithAudio:(NSString *)audioPath
               outputPath:(NSString *)outputPath
                 complete:(void(^)(NSString *path))complete;


/**
 m4a 转码至 mp3，实质为 m4a 先转为 WAV，再转为 mp3

 @param audioPath 需要转码的音频
 @param outputPath 输出路径
 @param complete 完成回调
 */
+ (void)m4aToMp3WithAudio:(NSString *)audioPath
               outputPath:(NSString *)outputPath
                 complete:(void(^)(NSString *path))complete;


/**
 获取音频的音量信息

 @param audioPath 音频地址
 @param sampleCount 样本数量
 @param height 样本最大值
 @param complete 完成回调，返回一个 NSNumber 的数组
 */
+ (void)getVoiceDataWithAudio:(NSString *)audioPath
                  sampleCount:(NSInteger)sampleCount
                       height:(CGFloat)height
                     complete:(void(^)(NSArray<NSNumber *> *voiceArray))complete;


/**
 寻找音频从何时开始有声音

 @param audioPath 音频地址
 @param startTime 从何时开始寻找
 @param voice 大于这个值代表有声音 1000 2000 3000等
 @param complete 完成回调，返回找到的开始时间
 */
+ (void)findBeginWithAudioPath:(NSString *)audioPath
                     startTime:(CGFloat)startTime
                         voice:(CGFloat)voice
                      complete:(void(^)(CGFloat time))complete;


/**
 调整PCM文件的音量
 
 @param audioPath 音频地址
 @param outputPath 输出地址
 @param rate 倍数，应该为大于0的float
 @param complete 完成回调
 */
+ (void)adjustPCMVolumeWithAuidoPath:(NSString *)audioPath
                          outputPath:(NSString *)outputPath
                                rate:(CGFloat)rate
                            complete:(void(^)(NSString *path))complete;

@end

