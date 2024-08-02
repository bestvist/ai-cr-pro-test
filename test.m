//
//  UIViewController+Config.m
//  WBJob
//
//  Created by ligang on 2022/3/25.
//

#import "UIViewController+cr_test.h"
#import <public3rd/MJExtension.h>
#import <wb3rd/NSObject+Additions.h>
#import <public3rd/JSONKit.h>
#import <WBRouter/WBRouterCenter.h>
#import "GanJiJobListRecordManager.h"
#define  kGanJiPageList    @{\
    @"GanJiBigCateContainerController":@"gj_homeJobList", \
    @"WBJobIMTabListController":@"gj_messageList",\
    @"WBJobIMChatController":@"gj_chatDetail",\
    @"GanJiEnterDictViewController":@"gj_enterpriseList",\
    @"GanjiSearchResultViewController":@"gj_searchResultList",\
    @"WBJobEmployNewViewController":@"gj_personalCenter",\
}

static char kActionConfigKey;
NSNotificationName const kGanJiActionConfigDidLoad = @"kGanJiActionConfigDidLoad";

static char kV2ActionConfigKey;

@implementation UIViewController (cr_test)

/** 目前和安卓同步每个需要的页面自己调用，如需支持所有页面，可解开以下代码 */
+ (void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceSelector:@selector(viewDidLoad) withNewSelector:@selector(action_viewDidLoad)];
    });
}

- (void)action_viewDidLoad{
    [self action_viewDidLoad];
    [self requestActionConfig];
}

- (void)requestActionConfig{
    
    NSString *name = [self getViewControllerNamespace];
    if ([NSString isEmpty:name]) return;
    [self requestActionConfigWithParams:@{@"namespace":name} complete:nil];
    
}

- (void)requestActionConfigWithParams:(NSDictionary *)params complete:(nullable void(^)( GanJiActionConfigModel * _Nullable actionConfig))complete{
    
    // 没有页面标识直接返回
    if(!params || [NSString isEmpty:[params valueForKey:@"namespace"]]) {
        if (complete) complete(nil);
        return;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    // 本次启动是不是安装后第一启动(进入首页才算)
    NSInteger firstLaunch = GanJiGlobalSharedCenter.defaultCenter.isFirstInstall ?1:0;
    [dict addEntriesFromDictionary:params.copy];
    [dict setValue:@(firstLaunch) forKey:@"firstLaunch"];
    __weak typeof(self) weakSelf = self;
    [WBJobNetwork requestTarget:self requestURL:kGanJi_ConfigEventList requestPramas:dict completionBlock:^(WBNetworkResponesResult resultType, id responseData) {
        if (resultType == WBNetworkResponesSuccess && [responseData isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSDictionary *data = [responseData valueForKey:@"data"];
                strongSelf.actionConfig = [GanJiActionConfigModel mj_objectWithKeyValues:data];
                if (complete) {
                    complete(strongSelf.actionConfig);
                    return; // 有回调自己处理，不走统一处理逻辑
                };
                [[NSNotificationCenter defaultCenter] postNotificationName:kGanJiActionConfigDidLoad object:strongSelf.actionConfig];
                [self sendEvent:GanJiActionConfigPageCreate eventValue:nil];
            });
        }
    }];
}

- (void)sendEvent:(GanJiActionConfigType)action eventValue:(nullable NSString *)eventValue{
    
    if (!self.actionConfig.itemMap.valid) {
        return;
    }
    NSArray <GanJiActionItmeModel *>*actionArray = nil;
    switch (action) {
        case GanJiActionConfigEvent:
            actionArray = self.actionConfig.itemMap.event.copy;
            break;
        case GanJiActionConfigSlider:
            actionArray = self.actionConfig.itemMap.slider.copy;
            break;
        case GanJiActionConfigPageCreate:
            actionArray = self.actionConfig.itemMap.pageCreate.copy;
            break;
        case GanJiActionConfigPageClose:
            actionArray = self.actionConfig.itemMap.pageClose.copy;
            break;
        case GanJiActionConfigPageShow:
            actionArray = self.actionConfig.itemMap.pageCreate.copy;
            break;
        default:
            break;
    }
    
    for (GanJiActionItmeModel *item in actionArray) {
        // 如果有事件标识，校验事件标识
        if ([NSString isValid:eventValue]) {
            if (![item.eventValue isEqualToString:eventValue]) {
                continue;
            }
        }
        
        // 只出一个未弹的弹窗
        if (item.isFinish == NO) {
            [WBRouterCenter routeToURLString:item.action];
            item.finish = YES;
            break;
        }
    }
}




- (NSString *)getViewControllerNamespace{
    return [kGanJiPageList valueForKey:NSStringFromClass(self.class)];
}

- (GanJiActionConfigModel *)actionConfig{
    return objc_getAssociatedObject(self, &kActionConfigKey);;
}

-(void)setActionConfig:(GanJiActionConfigModel *)actionConfig {
    objc_setAssociatedObject(self, &kActionConfigKey, actionConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 弹窗配置v2

- (void)requestV2ActionConfigWithParams:(NSDictionary *)params complete:(nullable void(^)( GanJiActionConfigModel * _Nullable actionConfig))complete
{
    // 没有页面标识直接返回
    if(!params || [NSString isEmpty:[params valueForKey:@"namespace"]]) {
        if (complete) complete(nil);
        return;
    }
    
    __weak typeof(self) weakSelf = self;

    [WBJobNetwork requestTarget:self requestURL:KGanji_AllPopUpWindowUrl requestPramas:params config:^(GanJiNetworkConfig *config) {
        NSDate *date = [NSDate new];
        NSString *timeSp = [NSString stringWithFormat:@"%d", (long)[date timeIntervalSince1970]];
        config.requestIdentifier = timeSp;
    } completionBlock:^(WBNetworkResponesResult resultType, id responseData) {
        if (resultType == WBNetworkResponesSuccess && [responseData isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                NSDictionary *data = [responseData valueForKey:@"data"];
                GanJiActionConfigModel *model = [GanJiActionConfigModel mj_objectWithKeyValues:data];
                strongSelf.v2ActionConfig = model;
                if (complete) {
                    complete(strongSelf.v2ActionConfig);
                    return; // 有回调自己处理，不走统一处理逻辑
                };
            });
        }
    }];


}

- (void)sendV2Event:(GanJiActionConfigType)action eventValue:(nullable NSString *)eventValue completeBlock:(void(^)(BOOL show))completeBlock
{
    if (!self.v2ActionConfig.itemMap.valid) {
        if (completeBlock) {
            completeBlock(NO);
        }
        return;
    }
    NSArray <GanJiActionItmeModel *>*actionArray = nil;
    switch (action) {
        case GanJiActionConfigEvent:
            actionArray = self.v2ActionConfig.itemMap.event.copy;
            break;
        case GanJiActionConfigSlider:
            actionArray = self.v2ActionConfig.itemMap.slider.copy;
            break;
        case GanJiActionConfigPageCreate:
            actionArray = self.v2ActionConfig.itemMap.pageCreate.copy;
            break;
        case GanJiActionConfigPageClose:
            actionArray = self.v2ActionConfig.itemMap.pageClose.copy;
            break;
        case GanJiActionConfigPageShow:
            actionArray = self.v2ActionConfig.itemMap.pageCreate.copy;
            break;
        default:
            break;
    }
    
    GanJiActionItmeModel *eventItemModel = nil;
    for (GanJiActionItmeModel *item in actionArray) {
        // 如果有事件标识，校验事件标识
        if ([NSString isValid:eventValue]) {
            if (![item.eventValue isEqualToString:eventValue]) {
                continue;
            }
        }
        eventItemModel = item;
        if (eventItemModel) break;
    }
    
    if (!eventItemModel) {
        if (completeBlock) {
            completeBlock(NO);
        }
        return;
    }
    
    if (eventItemModel.details.count == 0) {
        if (completeBlock) {
            completeBlock(NO);
        }
        return;
    }
    
    [self sendV2Event:eventItemModel completeBlock:completeBlock];
}

- (void)sendV2Event:(GanJiActionItmeModel *)eventItemModel completeBlock:(void (^)(BOOL))completeBlock{
    GanJiDetailsDataModel *model = [eventItemModel.details firstObject];
    
    if (model.action) {//路由弹窗
        [WBRouterCenter routeToURLString:model.action];
        if ([self respondsToSelector:@selector(executeEventWithCustomReport:commonParams:)]) {
            [self executeEventWithCustomReport:model commonParams:@{}];
        }else {
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setValue:model.noticeConfigKey forKey:@"noticeConfigKey"];
            [params setValue:@"show" forKey:@"reportType"];
            [self reportPopupWithParams:params];
        }
        [self removeDetailItem:model fromActionItem:eventItemModel];
        if (completeBlock) {
            completeBlock(YES);
        }
        return;
    }
    
    //通过下发数据弹窗
    if ([self respondsToSelector:@selector(showPopuViewWithData:completeBlock:)]) {
        
        [self showPopuViewWithData:model completeBlock:^(BOOL show, NSDictionary * _Nonnull commonParams) {
            if (show) {
                if ([self respondsToSelector:@selector(executeEventWithCustomReport:commonParams:)]) {
                    [self executeEventWithCustomReport:model commonParams:commonParams];
                } else {
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    [params setValue:model.noticeConfigKey forKey:@"noticeConfigKey"];
                    [params setValue:@"show" forKey:@"reportType"];
                    if (commonParams.count>0) {
                        [params setValue:[commonParams JSONString] forKey:@"commonParams"];
                    }
                    [self reportPopupWithParams:params];
                }
                [self removeDetailItem:model fromActionItem:eventItemModel];
            }
            
            if (completeBlock) {
                completeBlock(show);
            }

        }];
        return;
    }
    
    if (completeBlock) {
        completeBlock(NO);
    }
    
}
//弹窗移除
- (void)removeDetailItem:(GanJiDetailsDataModel *)model fromActionItem:(GanJiActionItmeModel*)actionItem
{
    NSMutableArray *marr = [NSMutableArray arrayWithArray:actionItem.details];
    [marr removeObject:model];
    actionItem.details = [marr copy];
}

//弹窗曝光
- (void)reportPopupWithParams:(NSDictionary *)params
{
    [WBJobNetwork requestTarget:self postURL:KGanji_PopUpWindow requestPramas:params completionBlock:^(WBNetworkResponesResult resultType, id responseData) {
        
    }];
}

// 驾驶舱上报
+ (void)reportEventWithParams:(NSDictionary *)params completion:(void (^)(BOOL success, id responseData))completion {
    [WBJobNetwork requestTarget:self postURL:KGanji_PopUpWindow requestPramas:params completionBlock:^(WBNetworkResponesResult resultType, id responseData) {
        if (resultType == WBNetworkResponesSuccess) {
            if ([responseData[@"code"] intValue] != 0) {
                if (completion) completion(NO,responseData);
            }else{
                if (completion) completion(YES,responseData);
            }
        } else {
            if (completion) completion(NO, responseData);
        }
    }];
}


- (GanJiActionConfigModel *)v2ActionConfig{
    return objc_getAssociatedObject(self, &kV2ActionConfigKey);;
}

-(void)setV2ActionConfig:(GanJiActionConfigModel *)v2ActionConfig {
    objc_setAssociatedObject(self, &kV2ActionConfigKey, v2ActionConfig, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
