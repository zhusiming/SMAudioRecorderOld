//
//  ViewController.h
//  SMAudioRecorder
//
//  Created by zsm on 14-12-5.
//  Copyright (c) 2014年 zsm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMAudioRecorder.h"

@interface ViewController : UIViewController
{
    NSString *_filePath;
}


- (IBAction)stopSoundRecording:(UIButton *)sender;

- (IBAction)startSoundRecording:(UIButton *)sender;

- (IBAction)playerSoundRecording:(UIButton *)sender;


@end

