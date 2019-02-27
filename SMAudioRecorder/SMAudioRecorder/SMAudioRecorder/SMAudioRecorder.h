//
//  SMAudioRecorder.h
//  SMAudioRecorder
//
//  Created by zsm on 14-12-5.
//  Copyright (c) 2014年 zsm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>

#import "VoiceConverter.h"

/*
    使用说明：
        第三方转码类库，因为该静态类库使用的是32位编译器打包的静态文件，所以集成需要更改编译器设置
        设置Build Active Architecture Only 为 NO
        Valid Architectures 为armv6 armv7 armv7s
        Bitcode:设置为NO
 */

// 录制音频的wav路径，和自动转码amr的路径
#define AMR_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/vido1.amr"]
#define WAV_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/vido2.wav"]

// 音频最短录制时间
#define MIN_TIME 1.0

/**
 *  录音时，监听话筒音量的block
 *
 *  @param volume        返回当前检测话筒声音的音量
 *  @param currentTime   录制时间（秒）
 */
typedef void(^VolumeChangedBlock)(CGFloat volume ,NSTimeInterval currentTime);

/**
 *  播放时，监听播放结束的block
 *
 */
typedef void(^DidFinishPlayingBlock)(void);

/**
 *  完成停止录音后回调的block
 *
 *  @param complete    录音是否成功，失败条件为录音时间小于 MIN_TIME
 *  @param amrfilePath 成功后返回录音文件amr的路径
 */
typedef void(^StopAudioRecorder)(BOOL complete ,NSString *amrfilePath, NSTimeInterval currentTime);

@interface SMAudioRecorder : NSObject<AVAudioRecorderDelegate,AVAudioPlayerDelegate>

/// 音量波动视图
@property (strong, nonatomic) NSArray *volumeImageNames;
/// 麦克风音量图片视图
@property (strong, nonatomic, readonly) UIImageView *recordImageView;
/// 麦克风音量视图
@property (strong, nonatomic, readonly) UIView *recordView;
/// 图片填充
@property (assign, nonatomic) UIEdgeInsets recordImageInsets;
/// 设置动画视图偏移量
@property (assign, nonatomic) CGFloat deviation_y;


/**
 *  单例设计模式（创建和使用对象都用此方法）
 *
 *  @return 返回当前音频录制对象
 */
+ (instancetype)shareAudioRecorder;


/**
 *  开始录音
 *
 *  @param display            是否现实话筒提示视图
 *  @param volumeChangedBlock 当前话筒音量监听
 */
- (void)startAudioRecorderWithDisplayMicrophone:(BOOL)display
                             VolumeChangedBlock:(VolumeChangedBlock)volumeChangedBlock;

/**
 *  停止录音的方法
 *
 *  @param stopAudioRecorder 完成录音后的block回掉
 */
- (void)stopAudioRecorderWithStopAudioRecorder:(StopAudioRecorder)stopAudioRecorder;

/**
 *  删除录制文件
 */
- (void)deleteRecording;

/**
 *  播放本地音频文件
 *
 *  @param urlString 音频文件的地址
 *  @param isAmr     当前音频文件是否是amr格式的，如果是自动转码成wav
 */
- (void)playerAudioRecorderWithPlayerUrl:(NSString *)urlString
                                amrToWav:(BOOL)isAmr
                             finishBlock:(DidFinishPlayingBlock)finishBlock;

/**
 *  停止正在播放的音频
 */
- (void)stop;
@end
