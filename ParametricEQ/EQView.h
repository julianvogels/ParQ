//
//  EQView.h
//  ParametricEQ
//
//  Created by Julian Vogels on 25/09/14.
//  Copyright (c) 2014 Julian Vogels. All rights reserved.
//

#import "constant.h"
#import <UIKit/UIKit.h>
#import "Utils.h"

@interface EQView : UIView

@property (strong, nonatomic) NSMutableArray *points;
@property (assign, nonatomic) CGFloat normLineY;

@property (strong, nonatomic) NSMutableArray *labels;

@end
