//
//  SMAudioRecorder.m
//  SMAudioRecorder
//
//  Created by zsm on 14-12-5.
//  Copyright (c) 2014年 zsm. All rights reserved.
//

#import "SMAudioRecorder.h"
static SMAudioRecorder *single = nil;

@interface SMAudioRecorder ()
@property (strong, nonatomic) AVAudioRecorder *recorder;         // 音频录制对象
@property (strong, nonatomic) NSTimer *timer;                    // 定时器

@property (strong, nonatomic) AVAudioPlayer *avPlayer;
@property (strong, nonatomic) VolumeChangedBlock volumeChangedBlock;
@property (strong, nonatomic) DidFinishPlayingBlock didFinishPlayingBlock;

/// 麦克风音量图片视图
@property (strong, nonatomic) UIImageView *recordImageView;
/// 麦克风音量视图
@property (strong, nonatomic) UIView *recordView;

@end


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
    if (_recordView.superview != nil) {
        [_recordView removeFromSuperview];
    }
    
    double cTime = _recorder.currentTime;
    if (cTime > MIN_TIME) {//如果录制时间<2 不发送
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 音频转码
            // wav 格式音频转为 amr 格式音频
            [VoiceConverter ConvertWavToAmr:WAV_PATH amrSavePath:AMR_PATH];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.volumeChangedBlock = nil;
                [self.recorder stop];
                [self.timer invalidate];
                stopAudioRecorder(YES,AMR_PATH,cTime);
            });
        });

        
    }else {
        //删除记录的文件
        [self deleteRecording];
        stopAudioRecorder(NO,nil,0);
    }
}

- (void)detectionVoice
{
    [_recorder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [_recorder averagePowerForChannel:0];
    
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    
    
    if (_recordView.superview != nil && self.volumeImageNames.count > 0) {
        int index = level * (self.volumeImageNames.count - 1);
        //图片 小-》大
        [_recordImageView setImage:[UIImage imageNamed:self.volumeImageNames[index]]];
    }
    if (_volumeChangedBlock) {
        _volumeChangedBlock(level,_recorder.currentTime);
    }
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
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    //  显示话筒
    if (display == YES && self.volumeImageNames.count > 0) {
        UIImage *firstImag = [UIImage imageNamed:self.volumeImageNames[0]];
        self.recordImageView.frame = CGRectMake(self.recordImageInsets.left, self.recordImageInsets.top, firstImag.size.width, firstImag.size.height);
        self.recordImageView.image = firstImag;
        
        self.recordView.frame = CGRectMake(0, 0, firstImag.size.width + self.recordImageInsets.left + self.recordImageInsets.right, firstImag.size.height + self.recordImageInsets.top + self.recordImageInsets.bottom);
        self.recordView.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, [UIApplication sharedApplication].keyWindow.center.y + self.deviation_y);
        [self.recordView addSubview:self.recordImageView];
        [[UIApplication sharedApplication].keyWindow addSubview:self.recordView];
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
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
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
    _volumeChangedBlock = nil;
    [_recorder deleteRecording];
    
    // 删除转码的文件
    [[NSFileManager defaultManager] removeItemAtPath:AMR_PATH error:nil];
    
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
- (void)playerAudioRecorderWithPlayerUrl:(NSString *)urlString
                                amrToWav:(BOOL)isAmr
                             finishBlock:(DidFinishPlayingBlock)finishBlock
{
    if (finishBlock) {
        _didFinishPlayingBlock = [finishBlock copy];
    }
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    if (isAmr == YES) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 音频转码
            [VoiceConverter ConvertAmrToWav:urlString wavSavePath:WAV_PATH];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.avPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:WAV_PATH] error:nil];
                self.avPlayer.volume=1.0;
                self.avPlayer.delegate = self;
                [self.avPlayer play];
            });
        });
    } else {
        _avPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL fileURLWithPath:urlString] error:nil];
        _avPlayer.delegate = self;
        _avPlayer.volume=1.0;
        [_avPlayer play];
    }
    
}

/**
 *  停止正在播放的音频
 */
- (void)stop
{
    _avPlayer.delegate = nil;
    [_avPlayer stop];
    _avPlayer = nil;
}

#pragma mark -
#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (_didFinishPlayingBlock) {
        _didFinishPlayingBlock();
    }
    _didFinishPlayingBlock = nil;
}
#pragma mark -
#pragma mark - getter
/// 麦克风音量图片视图
- (UIImageView *)recordImageView
{
    if (_recordImageView == nil) {
        _recordImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _recordImageView;
}
/// 麦克风音量视图
- (UIView *)recordView
{
    if (_recordView == nil) {
        _recordView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return _recordView;
}

@end
