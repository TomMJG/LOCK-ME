//
//  Waver.h
//  LOCK ME
//
//  Created by 马家固 on 16/3/22.
//  Copyright © 2016年 马家固. All rights reserved.
//

#ifndef Waver_h
#define Waver_h
#import <UIKit/UIKit.h>


@interface Waver : UIView

@property (nonatomic, copy) void (^waverLevelCallback)(Waver * waver);

//

@property (nonatomic) NSUInteger numberOfWaves;

@property (nonatomic) UIColor * waveColor;

@property (nonatomic) CGFloat level;

@property (nonatomic) CGFloat mainWaveWidth;

@property (nonatomic) CGFloat decorativeWavesWidth;

@property (nonatomic) CGFloat idleAmplitude;

@property (nonatomic) CGFloat frequency;

@property (nonatomic, readonly) CGFloat amplitude;

@property (nonatomic) CGFloat density;

@property (nonatomic) CGFloat phaseShift;

//

@property (nonatomic, readonly) NSMutableArray * waves;

@end


#endif /* Waver_h */
