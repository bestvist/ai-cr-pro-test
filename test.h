//
//  UIViewController+Config.h
//  WBJob
//
//  Created by ligang on 2022/3/25.
//

#import <UIKit/UIKit.h>
#import <WBJob/GanJiActionConfigModel.h>

NS_ASSUME_NONNULL_BEGIN

/**每个页面进入时 拉取配置*/
@interface UIViewController (cr_test)
@property (nonatomic, strong) GanJiActionConfigModel *actionConfig;
- (void)requestActionConfig;

/**
 * 1.支持个性化请求，必须在参数中传入页面标识 namespace,
 * 2.需要取消kGanJiPageList里面的配置，避免重复请求
 */
- (void)requestActionConfigWithParams:(NSDictionary *)params complete:(nullable void(^)( GanJiActionConfigModel * _Nullable actionConfig))complete;

/** 触发具体事件 */
- (void)sendEvent:(GanJiActionConfigType)action eventValue:(nullable NSString *)eventValue;

/** 触发一个具体事件 是下面方法的后半部分*/
- (void)sendV2Event:(GanJiActionItmeModel *)itemModel completeBlock:(void(^)(BOOL show))completeBlock;

/** 触发具体事件 v2*/
- (void)sendV2Event:(GanJiActionConfigType)action eventValue:(nullable NSString *)eventValue completeBlock:(void(^)(BOOL show))completeBlock;

/**v2
 * 1.支持个性化请求，必须在参数中传入页面标识 namespace,
 * 2.需要取消kGanJiPageList里面的配置，避免重复请求
 */
- (void)requestV2ActionConfigWithParams:(NSDictionary *)params complete:(nullable void(^)( GanJiActionConfigModel * _Nullable actionConfig))complete;

/**v2
 * 获取配置数据
 */
- (GanJiActionConfigModel *)v2ActionConfig;

/**
 v2
 复写：事件触发，自定义上报
 */
- (void)executeEventWithCustomReport:(GanJiDetailsDataModel *)model commonParams:(NSDictionary *)commonParams;

/**v2
 * 需要复写，通过下发数据展示某个弹窗
 */
- (void)showPopuViewWithData:(GanJiDetailsDataModel*)model completeBlock:(void(^)(BOOL show, NSDictionary*commonParams))completeBlock;


// 驾驶舱上报
- (void)reportPopupWithParams:(NSDictionary *)params;

// 驾驶舱上报
+ (void)reportEventWithParams:(NSDictionary *)params completion:(void (^)(BOOL success, id responseData))completion;

@end

NS_ASSUME_NONNULL_END
