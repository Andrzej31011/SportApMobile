import 'package:sport_ap_mobile/core/utils/json_utils.dart';

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.meta,
    required this.links,
  });

  final List<T> data;
  final PaginationMeta meta;
  final PaginationLinks links;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final dataList = JsonUtils.asList(
      json['data'],
    ).map((item) => fromJson(JsonUtils.asMap(item))).toList();

    return PaginatedResponse<T>(
      data: dataList,
      meta: PaginationMeta.fromJson(JsonUtils.asMap(json['meta'])),
      links: PaginationLinks.fromJson(JsonUtils.asMap(json['links'])),
    );
  }
}

class PaginationMeta {
  const PaginationMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 15,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: JsonUtils.asInt(json['current_page']) ?? 1,
      lastPage: JsonUtils.asInt(json['last_page']) ?? 1,
      total: JsonUtils.asInt(json['total']) ?? 0,
      perPage: JsonUtils.asInt(json['per_page']) ?? 15,
    );
  }
}

class PaginationLinks {
  const PaginationLinks({this.first, this.last, this.prev, this.next});

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory PaginationLinks.fromJson(Map<String, dynamic> json) {
    return PaginationLinks(
      first: JsonUtils.asString(json['first']),
      last: JsonUtils.asString(json['last']),
      prev: JsonUtils.asString(json['prev']),
      next: JsonUtils.asString(json['next']),
    );
  }
}
