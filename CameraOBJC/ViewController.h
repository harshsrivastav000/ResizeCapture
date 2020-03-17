//
//  ViewController.h
//  CameraOBJC
//
//  Created by harsh on 13/03/20.
//  Copyright © 2020 harsh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TOUtility.h"
#import <AVFoundation/AVFoundation.h>
#import "CameraOBJC-Swift.h"


@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *cameraLayer;
@property (weak, nonatomic) IBOutlet UIImageView *watermarkImageView;
@property (strong, nonatomic)  AVAssetExportSession *exporter;
@property (strong, nonatomic) CameraManager *cameraManager;
@property (weak, nonatomic) IBOutlet UIView *rectCrop;

@property(nonatomic) BOOL isRecording;
@end

