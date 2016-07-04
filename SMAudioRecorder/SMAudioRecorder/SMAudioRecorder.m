//
//  SMAudioRecorder.m
//  SMAudioRecorder
//
//  Created by zsm on 14-12-5.
//  Copyright (c) 2014年 zsm. All rights reserved.
//

#import "SMAudioRecorder.h"
static SMAudioRecorder *single = nil;
@implementation SMAudioRecorder

// 单利模式
+ (instancetype)shareAudioRecorder
{
    @synchronized(self){
        if (single == nil) {
            single = [[self alloc] init];
        }
    }
    return  single;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        //录音设置
        [self audio];
    }
    return self;
}

//录音设置
- (void)audio
{
    //录音设置
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc]init];
    //设置录音格式  AVFormatIDKey==kAudioFormatLinearPCM
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    //设置录音采样率(Hz) 如：AVSampleRateKey==8000/44100/96000（影响音频的质量）
    [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
    //录音通道数  1 或 2
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    //线性采样位数  8、16、24、32
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //录音的质量
    [recordSetting setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];

    NSURL *wavUrl = [NSURL fileURLWithPath:WAV_PATH];
    
    NSError *error;
    //初始化
    _recorder = [[AVAudioRecorder alloc]initWithURL:wavUrl settings:recordSetting error:&error];
    //开启音量检测
    _recorder.meteringEnabled = YES;
    _recorder.delegate = self;
    
    
    // 判断版本
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        
        //7.0第一次运行会提示，是否允许使用麦克风
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        NSError *sessionError;
        
        //AVAudioSessionCategoryPlayAndRecord用于录音和播放
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        if(session == nil) {
            
            
        } else
            
            [session setActive:YES error:nil];
    }
    
}

/**
 *  停止录音的方法
 *
 *  @return 如果返回nil说明录制时间小于1秒，否则放回_amr文件路径
 */

/**
 *  停止录音的方法
 *
 *  @param stopAudioRecorder 完成录音后的block回掉
 */
- (void)stopAudioRecorderWithStopAudioRecorder:(StopAudioRecorder)stopAudioRecorder
{
    if (_recordImageView.superview != nil) {
        [_recordImageView removeFromSuperview];
    }
    
    double cTime = _recorder.currentTime;
    if (cTime > MIN_TIME) {//如果录制时间<2 不发送
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 音频转码
            // wav 格式音频转为 amr 格式音频
            [VoiceConverter wavToAmr:WAV_PATH amrSavePath:AMR_PATH];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_recorder stop];
                [_timer invalidate];
                stopAudioRecorder(YES,AMR_PATH);
            });
        });

        
    }else {
        //删除记录的文件
        [self deleteRecording];
        stopAudioRecorder(NO,nil);
    }
}

- (void)detectionVoice
{
    [_recorder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    int volume = ([_recorder peakPowerForChannel:0] + 40);
    volume = MIN(40, volume);
    volume = MAX(0, volume);
    
    if (_recordImageView.superview != nil) {
        //图片 小-》大
        if (volume <= 5) {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_0.png"]];
        } else if (volume <= 10) {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_1.png"]];
        } else if (volume <= 15) {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_2.png"]];
        } else if (volume <= 20) {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_3.png"]];
        } else if (volume <= 35) {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_4.png"]];
        } else {
            [_recordImageView setImage:[UIImage imageNamed:@"mic_5.png"]];
        }
        
    }
    _volumeChangedBlock(volume,_recorder.currentTime);
    
    
    
}

/**
 *  开始录音
 *
 *  @param display            是否现实话筒提示视图
 *  @param volumeChangedBlock 当前话筒音量监听
 */
- (void)startAudioRecorderWithDisplayMicrophone:(BOOL)display
                             VolumeChangedBlock:(VolumeChangedBlock)volumeChangedBlock
{
    //  显示话筒
    if (display == YES) {
        if (_recordImageView == nil) {
            _recordImageView = [[UIImageView alloc]initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width - 140)/2, ([UIScreen mainScreen].bounds.size.height - 20 - 44 - 44 - 140)/2, 140, 140)];
            _recordImageView.contentMode = UIViewContentModeScaleAspectFill;
            _recordImageView.backgroundColor = [UIColor grayColor];
            _recordImageView.alpha = 0.5;
            _recordImageView.layer.masksToBounds = YES;
            _recordImageView.layer.cornerRadius = 8;
            
        }
        _recordImageView.image = [UIImage imageNamed:@"mic_0.png"];
        [[UIApplication sharedApplication].keyWindow addSubview:_recordImageView];
    }
    
    
    //创建录音文件，准备录音
    if ([_recorder prepareToRecord]) {
        //开始
        [_recorder record];
    }
    
    // 如果显示话筒视图或者监听音量
    if (display == YES || volumeChangedBlock != nil) {
        
        if (volumeChangedBlock != nil) {
            _volumeChangedBlock = [volumeChangedBlock copy];
        } else {
            _volumeChangedBlock = nil;
        }
        // 设置定时检测
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
    }
    
}


/**
 *  删除录制文件
 */
- (void)deleteRecording
{
    // 删除录制文件
    [_recorder stop];
    [_timer invalidate];
    [_recorder deleteRecording];
    
    // 删除转码的文件
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:AMR_PATH error:nil];
    
    // 视图移除
    if (_recordImageView.superview != nil) {
        [_recordImageView removeFromSuperview];
    }
}

/**
 *  播放本地音频文件
 *
 *  @param urlString 音频文件的地址
 *  @param isAmr     当前音频文件是否是amr格式的，如果是自动转码成wav
 */
- (void)playerAudioRecorderWithPlayerUrl:(NSString *)urlString amrToWav:(BOOL)isAmr
{
    if (isAmr == YES) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 音频转码
            [VoiceConverter amrToWav:urlString wavSavePath:WAV_PATH];
            dispatch_async(dispatch_get_main_queue(), ^{
                _avPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:WAV_PATH] error:nil];
                _avPlayer.volume=1.0;
                [_avPlayer play];
            });
        });
    } else {
        _avPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:urlString] error:nil];
        _avPlayer.volume=1.0;
        [_avPlayer play];
    }
    
}

@end
