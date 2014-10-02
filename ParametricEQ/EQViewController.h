//
//  EQViewController.h
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import <UIKit/UIKit.h>
// ParQDSP
#import "ParQDSP.h"
// Basic Graphics
#import <QuartzCore/QuartzCore.h>
// Contants
#import "constant.h"
// EQView
#import "EQView.h"
// Utils
#import "Utils.h"

// Pick iTunes Song

#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@interface EQViewController : UIViewController <JVPeakingEQDelegate, MPMediaPickerControllerDelegate>

// ParQDSP
@property (strong, nonatomic) ParQDSP *dsp;

// Magnitude response
@property (strong, nonatomic) NSMutableArray *frequencyLocations;

// UI Elements
@property (strong, nonatomic) IBOutlet EQView *eqView;
@property (strong, nonatomic) IBOutlet UIButton *micButton;
@property (strong, nonatomic) IBOutlet UILabel *freqLabel;
@property (strong, nonatomic) IBOutlet UILabel *gainLabel;
@property (strong, nonatomic) IBOutlet UILabel *qLabel;
@property (strong, nonatomic) IBOutlet UIButton *qButton;
@property (strong, nonatomic) IBOutlet UIButton *soundFileButton;

// Actions
- (IBAction)micButtonTouchUpInside:(id)sender;
- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)sender;
- (IBAction)panGesture:(UIPanGestureRecognizer *)sender;
- (IBAction)qButtonTouchUpInside:(id)sender;
- (IBAction)SoundFileButtonTouchUpInside:(id)sender;


@end
