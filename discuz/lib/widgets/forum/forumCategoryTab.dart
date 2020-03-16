import 'package:dio/dio.dart';
import 'package:discuzq/ui/ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:md2_tab_indicator/md2_tab_indicator.dart';

import 'package:discuzq/models/appModel.dart';
import 'package:discuzq/utils/request/request.dart';
import 'package:discuzq/utils/urls.dart';
import 'package:discuzq/widgets/common/discuzText.dart';

/// 注意：
/// 从我们的设计上来说，要加载了forum才显示这个组件，所以forum请求自然就在category之前
/// 这样做的目的是为了不要一次性请求过多，来尽量避免阻塞，所以在使用这个组件到其他地方渲染的时候，你也需要这样做
class ForumCategory extends StatefulWidget {
  const ForumCategory({Key key}) : super(key: key);
  @override
  _ForumCategoryState createState() => _ForumCategoryState();
}

class _ForumCategoryState extends State<ForumCategory>
    with SingleTickerProviderStateMixin {
  /// states
  /// tab controller
  TabController _tabController;

  /// _loading will be true when request categories, but not tell you success or failed to load
  /// default should be true, so that you can make a loading animation for users
  bool _loading = true;

  /// categories is empty
  bool _isEmptyCategories = false;

  @override
  void setState(fn) {
    if (!mounted) {
      return;
    }
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();

    /// 延迟加载
    Future.delayed(Duration(milliseconds: 400))
        .then((_) => this._initTabController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScopedModelDescendant<AppModel>(
      rebuildOnChange: true,
      builder: (context, child, model) => _buildForumCategoryTab(model));

  /// 构造tabbar
  Widget _buildForumCategoryTab(AppModel model) {
    /// 返回加载中的视图
    if (_loading) {
      return const Center(
        child: const CupertinoActivityIndicator(),
      );
    }

    /// 返回没有可用分类
    if (_isEmptyCategories) {
      const Center(child: const DiscuzText('暂无可用分类'));
    }

    /// 生成论坛分类和内容区域
    return Column(
      children: <Widget>[
        /// 生成滑动选项
        _buildtabs(model),

        /// 生成帖子渲染content区域(tabviews)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: model.categories.map<Widget>((e) {
              //创建3个Tab页
              return Container(
                alignment: Alignment.center,
                child: DiscuzText(e['attributes']['name'], textScaleFactor: 5),
              );
            }).toList(),
          ),
        )
      ],
    );
  }

  Widget _buildtabs(AppModel model) => Container(
        width: MediaQuery.of(context).size.width,
        decoration:
            BoxDecoration(color: DiscuzApp.themeOf(context).backgroundColor),
        child: TabBar(
            //生成Tab菜单
            controller: _tabController,
            labelStyle: TextStyle(
                //up to your taste
                fontSize: DiscuzApp.themeOf(context).normalTextSize,),
            indicatorSize: TabBarIndicatorSize.label, //makes it better
            labelColor:
                DiscuzApp.themeOf(context).primaryColor, //Google's sweet blue
            unselectedLabelColor:
                DiscuzApp.themeOf(context).textColor, //niceish grey
            isScrollable: true, //up to your taste
            indicator: MD2Indicator(
                //it begins here
                indicatorHeight: 3,
                indicatorColor: DiscuzApp.themeOf(context).primaryColor,
                indicatorSize:
                    MD2IndicatorSize.normal //3 different modes tiny-normal-full
                ),
            tabs: model.categories
                .map<Widget>((e) => Tab(text: e['attributes']['name']))
                .toList()),
      );

  /// 初始化 tab controller
  ///
  /// 该方法将会请求查询分类接口以构造一个 tabs 列表
  ///
  Future<void> _initTabController() async {
    try {
      final AppModel model =
          ScopedModel.of<AppModel>(context, rebuildOnChange: true);

      final bool success = await _getCategories(model);
      if (!success) {
        return;
      }

      /// 没有分类
      if (model.categories == null || model.categories.length == 0) {
        setState(() {
          _isEmptyCategories = true;
        });
      }

      /// 初始化tabber
      _tabController = TabController(
          length: model.categories == null ? 0 : model.categories.length,
          vsync: this);
    } catch (e) {
      print(e);
    }
  }

  /// _getCategories
  /// force should never be true on didChangeDependencies life cycle
  /// that would make your ui rendering loop and looping to die
  Future<bool> _getCategories(AppModel model, {bool force = false}) async {
    setState(() {
      _loading = true;
      _isEmptyCategories = false;

      /// 仅需要复原 _initTabController会再次处理
    });
    Response resp =
        await Request(context: context).getUrl(url: Urls.categories);

    setState(() {
      _loading = false;
    });

    if (resp == null) {
      return Future.value(false);
    }

    /// 更新状态
    model.updateCategories(resp.data['data']);

    return Future.value(true);
  }
}
