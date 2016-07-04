//
//  ViewController.m
//  SMAudioRecorder
//
//  Created by zsm on 14-12-5.
//  Copyright (c) 2014年 zsm. All rights reserved.
//

#import "ViewController.h"
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (IBAction)stopSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] stopAudioRecorderWithStopAudioRecorder:^(BOOL complete, NSString *amrfilePath) {
        _filePath = amrfilePath;
    }];
}

- (IBAction)startSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] startAudioRecorderWithDisplayMicrophone:YES VolumeChangedBlock:^(int volume ,NSTimeInterval currentTime) {
        NSLog(@"%d,%f",volume,currentTime);
    }];
}

- (IBAction)playerSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] playerAudioRecorderWithPlayerUrl:_filePath amrToWav:YES];
}

@end
