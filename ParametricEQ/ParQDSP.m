//
//  ParQDSP.m
//  ParametricEQ
//
//  Created by Julian Vogels on 02/10/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "ParQDSP.h"

@interface ParQDSP ()

@property (assign, nonatomic) RingBuffer *ringBuffer;

@end


@implementation ParQDSP{
    struct {
        unsigned int updateLevelMeter:1;
        unsigned int filterCoefficients:1;
    } delegateRespondsTo;
    
}
@synthesize delegate;

- (void)setDelegate:(id <JVPeakingEQDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
        
        delegateRespondsTo.updateLevelMeter = [delegate respondsToSelector:@selector(updateLevelMeter:)];
        delegateRespondsTo.filterCoefficients = [delegate respondsToSelector:@selector(filterCoefficients:)];
    }
}


// Novocaine
@synthesize audioManager;
@synthesize ringBuffer;
@synthesize JVPEF;

@synthesize fs;



-(void)initDSP {
    
    ringBuffer = new RingBuffer(32768, 2);
    audioManager = [Novocaine audioManager];
    fs = audioManager.samplingRate;
    
    // NVDSP Peaking EQ Filter init
    JVPEF = [[JVPeakingEQ alloc] initWithSamplingRate:audioManager.samplingRate];
    JVPEF.sampleRate = self.audioManager.samplingRate;
    
    JVPEF.delegate = self.delegate;

    
    if (PARQ_DEFAULTS_INPUT) {
        [self setupFilterWithMicInput];
    } else {
        [self setupFilterWithSoundFileURL:[[NSBundle mainBundle] URLForResource:@"apfelsinen" withExtension:@"m4a"]];
    }
    
    JVPEF.centerFrequency = PARQ_DEFAULTS_F0;
    JVPEF.Q = PARQ_DEFAULTS_Q;
    JVPEF.G = PARQ_DEFAULTS_G;
}

-(void)setupFilterWithMicInput {
    if (audioManager.playing) {
        [audioManager pause];
    }
    __weak ParQDSP *wself = self;

    /* ======================
     
     Input Block
     
     ====================== */
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        
            // Input scaling
            float volume = 0.5;
            vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
            wself.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
            
            float normVal = [wself audioLevelForData:data numFrames:numFrames numChannels:numChannels];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [wself.delegate updateLevelMeter:normVal];
                
            });
    }];
    
    /* ======================
     
     Output Block
     
     ====================== */
    
    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
        
        wself.ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
        
        [wself.JVPEF filterData:outData numFrames:numFrames numChannels:numChannels];
        
    }];
    
    
    [audioManager play];
}

-(void)setupFilterWithSoundFileURL:(NSURL *)fileUrl {
    if (fileUrl) {
    if (audioManager.playing) {
        [audioManager pause];
    }
    __weak ParQDSP *wself = self;
    
    
    /* ======================
     
     Input Block
     
     ====================== */
    
    [self.audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        // Do Nothing
    }];
     
    
    /* ======================
     
     File Reader
     
     ====================== */
    
        _fileReader = [[AudioFileReader alloc]
                       initWithAudioFileURL:fileUrl
                       samplingRate:audioManager.samplingRate
                       numChannels:audioManager.numOutputChannels];
        
        [_fileReader play];
        _fileReader.currentTime = 0.0;
    
    if (!fileUrl) {
        NSLog(@"File Reader error");
    }

    
    /* ======================
     
     Output Block
     
     ====================== */
    
    [self.audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {

        [wself.fileReader retrieveFreshAudio:outData numFrames:numFrames numChannels:numChannels];
        
        [wself.JVPEF filterData:outData numFrames:numFrames numChannels:numChannels];
        
    }];
    
    
    [audioManager play];
    } else {
        NSLog(@"WARNING: Could not set up filter - File URL not valid.");
    }
}


-(float)audioLevelForData:(float *)data numFrames:(UInt32)numFrames numChannels:(UInt32)numChannels{
    float dbVal = 0.0f;
    float normVal = 0.0f;
    vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
    float meanVal = 0.0;
    vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
    normVal = meanVal;
    float one = 1.0;
    vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
    dbVal = dbVal + 0.2*(meanVal - dbVal);
    
    normVal *= 10;
    if (normVal > 1.0) {
        normVal = 1.0;
    }
    
    return normVal;
}

@end
