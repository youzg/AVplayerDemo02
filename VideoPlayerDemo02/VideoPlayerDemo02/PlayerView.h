//
//  PlayerView.h
//  VideoWithAVPlayer
//
//  Created by YOUZG on 2017/2/7.
//  Copyright © 2017年 youzg. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PlayerStatus) {
    PlayerStatusWithPlay,
    PlayerStatusWithPause,
    PlayerStatusWithError
};

@class PlayerView;
@protocol PlayerDelegate <NSObject>


@end

@interface PlayerView : UIView

@property(nonatomic, readonly) NSTimeInterval currentPlaybackTime;
@property(nonatomic, readonly) NSTimeInterval duration;
@property(nonatomic, readonly) PlayerStatus status;
@property(nonatomic, assign) NSInteger seekTime;
@property(nonatomic, weak) id<PlayerDelegate> delegate;

- (void)playWithUrlString:(NSString *)urlString;


- (void)play;

- (void)pause;

- (void)cleanPlayer;

@end
