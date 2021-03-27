//
//  PHThemeManager.m
//  iOCNews
//
//  Created by Peter Hedlund on 10/29/17.
//  Copyright © 2017 Peter Hedlund. All rights reserved.
//

@import WebKit;

#import "PHThemeManager.h"
#import "OCFeedListController.h"
#import "iOCNews-Swift.h"
#import "ArticleController.h"

@implementation UILabel (ThemeColor)

- (void)setThemeTextColor:(UIColor *)themeTextColor {
    if (themeTextColor) {
        self.textColor = themeTextColor;
    }
}

@end

@implementation PHThemeManager

+ (PHThemeManager*)sharedManager {
    static dispatch_once_t once_token;
    static id sharedManager;
    dispatch_once(&once_token, ^{
        sharedManager = [[PHThemeManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        [self applyCurrentTheme];
    }
    return self;
}

- (PHTheme)currentTheme {
    return SettingsStore.theme;
}

- (void)setCurrentTheme:(PHTheme)currentTheme {
    SettingsStore.theme = currentTheme;
    ThemeColors *themeColors = [[ThemeColors alloc] init];

    [[[[UIApplication sharedApplication] delegate] window] setTintColor:themeColors.pbhIcon];
    
    [UINavigationBar appearance].barTintColor = themeColors.pbhPopoverButton;
    NSMutableDictionary<NSAttributedStringKey, id> *newTitleAttributes = [NSMutableDictionary<NSAttributedStringKey, id> new];
    newTitleAttributes[NSForegroundColorAttributeName] = themeColors.pbhText;
    [UINavigationBar appearance].titleTextAttributes = newTitleAttributes;
    [UINavigationBar appearance].tintColor = themeColors.pbhIcon;

    [UIBarButtonItem appearance].tintColor = themeColors.pbhText;

    [UITableViewCell appearance].backgroundColor = [[ThemeColors alloc] init].pbhCellBackground;

    UIColor *backgroundColor = [[[ThemeColors alloc] init] pbhBackground];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[ArticleListController class]]] setBackgroundColor: themeColors.pbhBackground];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[FeedCell class]]] setBackgroundColor:themeColors.pbhPopoverBackground];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:themeColors.pbhPopoverBackground];
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setBackgroundColor:themeColors.pbhPopoverButton];

    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[ArticleListController class]]] setBackgroundColor:themeColors.pbhCellBackground];
    [[UICollectionView appearanceWhenContainedInInstancesOfClasses:@[[ArticleController class]]] setBackgroundColor:themeColors.pbhCellBackground];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]] setBackgroundColor:themeColors.pbhPopoverBackground];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[SettingsViewController class]]] setBackgroundColor:themeColors.pbhPopoverBackground];
    [[UITableView appearanceWhenContainedInInstancesOfClasses:@[[ThemeSettings class]]] setBackgroundColor:themeColors.pbhPopoverBackground];

    [UIScrollView appearance].backgroundColor = themeColors.pbhCellBackground;
    [UIScrollView appearanceWhenContainedInInstancesOfClasses:@[[OCFeedListController class]]].backgroundColor = themeColors.pbhPopoverBackground;

    [[UILabel appearance] setThemeTextColor:themeColors.pbhText];

    [[UISwitch appearance] setOnTintColor:themeColors.pbhPopoverBorder];
    [[UISwitch appearance] setTintColor:themeColors.pbhPopoverBorder];

    [WKWebView appearance].backgroundColor = [[ThemeColors alloc] init].pbhCellBackground;

    [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITextField class]]] setThemeTextColor:themeColors.pbhReadText];
    [[UITextField appearance] setTextColor:themeColors.pbhText];
    [[UITextView appearance] setTextColor:themeColors.pbhText];
    [[UIStepper appearance] setTintColor:themeColors.pbhText];

    NSArray * windows = [UIApplication sharedApplication].windows;
    
    for (UIWindow *window in windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThemeUpdate" object:self];
    
}

- (void)applyCurrentTheme {
    PHTheme current = self.currentTheme;
    [self setCurrentTheme:current];
}

- (NSString *)themeName {
    switch (self.currentTheme) {
        case PHThemeDefault:
            return NSLocalizedString(@"Default", @"Name of the default theme");
            break;
        case PHThemeSepia:
            return NSLocalizedString(@"Sepia", @"Name of the sepia theme");
            break;
        case PHThemeNight:
            return NSLocalizedString(@"Night", @"Name of the night theme");
            break;
        default:
            return @"Default";
            break;
    }
}

@end
