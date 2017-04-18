//
//  PlayerView.m
//  VideoWithAVPlayer
//
//  Created by YOUZG on 2017/2/7.
//  Copyright © 2017年 youzg. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerView ()

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) id<NSObject> token;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@end

@implementation PlayerView

static int KVOContext = 0;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.seekTime = 0;
        [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.loadedTimeRanges" options:NSKeyValueObservingOptionNew context:&KVOContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.seekTime = 0;
        [self addObserver:self forKeyPath:@"asset" options:NSKeyValueObservingOptionNew context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.duration" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&KVOContext];
        [self addObserver:self forKeyPath:@"player.currentItem.loadedTimeRanges" options:NSKeyValueObservingOptionNew context:&KVOContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"释放当前playerView");
}

- (void)cleanPlayer {
        NSLog(@"清理开始");
        if (_token) {
            [self.player removeTimeObserver:_token];
            _token = nil;
        }
        
        [self.player pause];
        
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self removeObserver:self forKeyPath:@"asset" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.duration" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.rate" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.status" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.playbackBufferEmpty" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.playbackLikelyToKeepUp" context:&KVOContext];
    [self removeObserver:self forKeyPath:@"player.currentItem.loadedTimeRanges" context:&KVOContext];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.playerLayer.player = self.player;
}

- (void)asynchronouslyLoadURLAsset:(AVURLAsset *)newAsset {
    
    [newAsset loadValuesAsynchronouslyForKeys:[self assetKeysRequiredToPlay] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (newAsset != self.asset) {
                return ;
            }
            for (NSString *key in [self assetKeysRequiredToPlay]) {
                NSError *error = nil;
                if ([newAsset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed) {
                    return;
                }
            }
            
            if (!newAsset.playable || newAsset.hasProtectedContent) {
                return;
            }
            
            self.playerItem = [AVPlayerItem playerItemWithAsset:newAsset];
        });
    }];
}


#pragma mark - KVO
//监听回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if (context != &KVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if ([keyPath isEqualToString:@"asset"]) {
        if (self.asset) {
            [self asynchronouslyLoadURLAsset:self.asset];
        }
    } else if ([keyPath isEqualToString:@"player.currentItem.duration"]) {
        NSValue *newDurationAsValue = change[NSKeyValueChangeNewKey];
        CMTime newDuration = [newDurationAsValue isKindOfClass:[NSValue class]] ? newDurationAsValue.CMTimeValue : kCMTimeZero;
        BOOL hasValidDuration = CMTIME_IS_NUMERIC(newDuration) && newDuration.value != 0;
        double newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0;
        int wholeMinutes = (int)trunc(newDurationSeconds / 60);
        
        NSString *totalTime = [NSString stringWithFormat:@"%0d:%02d", wholeMinutes, (int)trunc(newDurationSeconds) - wholeMinutes * 60];
        CGFloat sliderValue = hasValidDuration ? (CMTimeGetSeconds(self.player.currentTime) / newDurationSeconds) : 0.0;

    } else if ([keyPath isEqualToString:@"player.rate"]) {
        double newRate = [change[NSKeyValueChangeNewKey] doubleValue];
        NSLog(@"不同状态:%lf", newRate);

    } else if ([keyPath isEqualToString:@"player.currentItem.status"]) {
        NSNumber *newStatusAsNumber = change[NSKeyValueChangeNewKey];
        AVPlayerItemStatus newStatus = [newStatusAsNumber isKindOfClass:[NSNumber class]] ? newStatusAsNumber.integerValue : AVPlayerItemStatusUnknown;
        NSLog(@"进入播放");
        if (newStatus == AVPlayerItemStatusReadyToPlay){
            if (self.seekTime > 0) {
                [self.player seekToTime:CMTimeMake(self.seekTime, 1)];
                self.seekTime = 0;
            }

        } else if (newStatus == AVPlayerItemStatusFailed) {

        }
    } else if ([keyPath isEqualToString:@"player.currentItem.playbackBufferEmpty"]) {
        NSLog(@"当缓冲开始的时候");

    } else if ([keyPath isEqualToString:@"player.currentItem.playbackLikelyToKeepUp"]) {
        NSLog(@"当缓冲结束的时候");

    } else if ([keyPath isEqualToString:@"player.currentItem.loadedTimeRanges"]) {
        NSArray *array = self.player.currentItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        //对比缓冲与当前位置


    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }

}

#pragma mark - NSNotification
- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"视频结束");
}

#pragma mark - Public Method
- (void)playWithUrlString:(NSString *)urlString {
    if (!urlString || urlString.length <= 0) {
        return;
    }
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]                                           forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    self.asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:urlString] options:opts];
    __weak typeof(self) weakSelf = self;
    _token = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {

        NSTimeInterval current = CMTimeGetSeconds(time);
        NSTimeInterval duration = weakSelf.duration;
    }];

}

- (void)play {
    if (self.player) {
        [self.player play];
    }
}

- (void)pause {
    if (self.player) {
        [self.player pause];
    }
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"duration"]) {
        return [NSSet setWithArray:@[@"player.currentItem.duration"]];
    } else if ([key isEqualToString:@"currentTime"]) {
        return [NSSet setWithArray:@[@"player.currentItem.currentTime" ]];
    } else if ([key isEqualToString:@"rate"]) {
        return [NSSet setWithArray:@[@"player.rate"]];
    } else if ([key isEqualToString:@"playbackBufferEmpty"]) {
        return [NSSet setWithArray:@[@"player.currentItem.playbackBufferEmpty"]];
    } else if ([key isEqualToString:@"playbackLikelyToKeepUp"]) {
        return [NSSet setWithArray:@[@"player.currentItem.playbackLikelyToKeepUp"]];
    } else if ([key isEqualToString:@"loadedTimeRanges"]) {
        return [NSSet setWithArray:@[@"player.currentItem.loadedTimeRanges"]];
    } else {
        return [super keyPathsForValuesAffectingValueForKey:key];
    }
}

#pragma mark - Class Method
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

#pragma mark - Setter Getter

- (NSTimeInterval)duration {
    if (self.player && self.player.currentItem) {
        return CMTimeGetSeconds(self.player.currentItem.asset.duration);
    }
    return 0;
}

- (PlayerStatus)status {
    if (self.player) {
        if (self.player.rate > 0 && self.player.error == nil) {
            return PlayerStatusWithPlay;
        } else if (self.player.rate == 0 && self.player.error == nil) {
            return PlayerStatusWithPause;
        } else {
            return PlayerStatusWithError;
        }
    }
    return PlayerStatusWithError;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_x_Max) {
            self.player.automaticallyWaitsToMinimizeStalling = NO;
        }
    }
    return _player;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem != playerItem) {
        _playerItem = playerItem;
        [self.player replaceCurrentItemWithPlayerItem:_playerItem];
    }
}

- (NSArray *)assetKeysRequiredToPlay {
    return @[@"playable", @"hasProtectedContent"];
}

@end
