//
//  ViewController.m
//  VideoPlayerDemo02
//
//  Created by YOUZG on 2017/4/18.
//  Copyright © 2017年 youzg. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet PlayerView *playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.playerView playWithUrlString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.playerView play];
}

- (void)dealloc {
    [self.playerView cleanPlayer];
}




@end
