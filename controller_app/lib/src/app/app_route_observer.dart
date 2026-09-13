import 'package:flutter/material.dart';

/// 统一监听页面路由可见性，供需要在被覆盖时暂停业务的页面使用。
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
