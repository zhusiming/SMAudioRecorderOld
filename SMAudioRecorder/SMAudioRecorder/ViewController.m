//
//  ViewController.m
//  SMAudioRecorder
//
//  Created by zhusiming on 2019/2/27.
//  Copyright © 2019 zhusiming. All rights reserved.
//

#import "ViewController.h"
#import "SMAudioRecorder.h"
@interface ViewController ()
@property (strong, nonatomic) NSString *filePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [SMAudioRecorder shareAudioRecorder].volumeImageNames = @[@"im_speak01",@"im_speak02",@"im_speak03",@"im_speak04",@"im_speak05",@"im_speak06",@"im_speak07",@"im_speak08",@"im_speak09"];
    [SMAudioRecorder shareAudioRecorder].recordView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [SMAudioRecorder shareAudioRecorder].recordView.layer.cornerRadius = 5;
    [SMAudioRecorder shareAudioRecorder].recordImageInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

- (IBAction)stopSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] stopAudioRecorderWithStopAudioRecorder:^(BOOL complete, NSString *amrfilePath, NSTimeInterval currentTime) {
        self.filePath = amrfilePath;
    }];
}

- (IBAction)startSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] startAudioRecorderWithDisplayMicrophone:YES VolumeChangedBlock:^(CGFloat volume ,NSTimeInterval currentTime) {
        NSLog(@"%f,%f",volume,currentTime);
    }];
}

- (IBAction)playerSoundRecording:(UIButton *)sender
{
    [[SMAudioRecorder shareAudioRecorder] playerAudioRecorderWithPlayerUrl:_filePath amrToWav:YES finishBlock:^{
    }];
}
@end
