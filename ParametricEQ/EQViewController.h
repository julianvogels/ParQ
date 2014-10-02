//
//  EQViewController.h
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import <UIKit/UIKit.h>
// Novocaine DSP
#import <Novocaine/Novocaine.h>
#import <Novocaine/AudioFileReader.h>
#import <Novocaine/RingBuffer.h>
// NVDSP
#import <NVDSP/NVPeakingEQFilter.h>
#import <NVDSP/NVDSP.h>
#import <Accelerate/Accelerate.h>
// Custom Class
#import "JVPeakingEQ.h"

// Basic Graphics
#import <QuartzCore/QuartzCore.h>
// Contants
#import "constant.h"
// EQView
#import "EQView.h"
// Utils
#import "Utils.h"

@interface EQViewController : UIViewController <JVPeakingEQDelegate> {
    float *gInputKeepBuffer[2];
    float *gOutputKeepBuffer[2];
}

// Novocaine
@property (strong, nonatomic) Novocaine *audioManager;
@property (strong, nonatomic) AudioFileReader *fileReader;
@property (assign, nonatomic) BOOL isRealTimeAudio;
@property (strong, nonatomic) JVPeakingEQ *JVPEF;

// Samplerate
@property (assign, nonatomic) float fs;

// Meta coeffs
@property (assign, nonatomic, setter=setCenterFrequency:) float f0;
@property (assign, nonatomic, setter=setGain:) float g;
@property (assign, nonatomic, setter=setQ:) float q;

// Coeffs
@property (strong, nonatomic) NSMutableArray *coeffs;
@property (assign, nonatomic) double b0, b1, b2, a0, a1, a2;

// Magnitude response
@property (strong, nonatomic) NSMutableArray *frequencyLocations;
@property (strong, nonatomic) NSMutableArray *magnitudesAtLocations;

// UI Elements
@property (strong, nonatomic) IBOutlet EQView *eqView;
@property (strong, nonatomic) IBOutlet UIButton *micButton;
@property (strong, nonatomic) IBOutlet UILabel *freqLabel;
@property (strong, nonatomic) IBOutlet UILabel *gainLabel;
@property (strong, nonatomic) IBOutlet UILabel *qLabel;
@property (strong, nonatomic) IBOutlet UIButton *qButton;

// Actions
- (IBAction)micButtonTouchUpInside:(id)sender;
- (IBAction)pinchGesture:(UIPinchGestureRecognizer *)sender;
- (IBAction)panGesture:(UIPanGestureRecognizer *)sender;
- (IBAction)qButtonTouchUpInside:(id)sender;


@end
