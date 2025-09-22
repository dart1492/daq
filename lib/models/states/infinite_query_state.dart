// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

enum InfiniteQueryLoadingState { initial, loading, loadingMore, success, error }

class InfiniteQueryState<TData, TParams, TError> {
  final List<TData> data;
  final TParams parameters;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final InfiniteQueryLoadingState loadingState;
  final TError? error;
  InfiniteQueryState({
    this.data = const [],
    required this.parameters,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalItems = 0,
    this.hasNextPage = false,
    this.loadingState = InfiniteQueryLoadingState.initial,
    this.error,
  });

  // Convenience getters
  bool get isLoading => loadingState == InfiniteQueryLoadingState.loading;
  bool get isLoadingMore =>
      loadingState == InfiniteQueryLoadingState.loadingMore;
  bool get isSuccess => loadingState == InfiniteQueryLoadingState.success;
  bool get hasError => loadingState == InfiniteQueryLoadingState.error;
  bool get isEmpty => data.isEmpty;
  bool get isNotEmpty => data.isNotEmpty;
  int get itemCount => data.length;

  InfiniteQueryState<TData, TParams, TError> copyWith({
    List<TData>? data,
    TParams? parameters,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    InfiniteQueryLoadingState? loadingState,
    TError? error,
  }) {
    return InfiniteQueryState<TData, TParams, TError>(
      data: data ?? this.data,
      parameters: parameters ?? this.parameters,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      loadingState: loadingState ?? this.loadingState,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'InfiniteQueryState(data: $data, parameters: $parameters, currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems, hasNextPage: $hasNextPage, loadingState: $loadingState, error: $error)';
  }

  @override
  bool operator ==(covariant InfiniteQueryState<TData, TParams, TError> other) {
    if (identical(this, other)) return true;

    return listEquals(other.data, data) &&
        other.parameters == parameters &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.totalItems == totalItems &&
        other.hasNextPage == hasNextPage &&
        other.loadingState == loadingState &&
        other.error == error;
  }

  @override
  int get hashCode {
    return data.hashCode ^
        parameters.hashCode ^
        currentPage.hashCode ^
        totalPages.hashCode ^
        totalItems.hashCode ^
        hasNextPage.hashCode ^
        loadingState.hashCode ^
        error.hashCode;
  }
}

class DAQInfiniteQueryResponse<T> {
  DAQInfiniteQueryResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
  });
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;

  DAQInfiniteQueryResponse<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
  }) {
    return DAQInfiniteQueryResponse<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }

  @override
  String toString() {
    return 'DAQInfiniteQueryResponse(items: $items, currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems, hasNextPage: $hasNextPage)';
  }

  @override
  bool operator ==(covariant DAQInfiniteQueryResponse<T> other) {
    if (identical(this, other)) return true;

    return listEquals(other.items, items) &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.totalItems == totalItems &&
        other.hasNextPage == hasNextPage;
  }

  @override
  int get hashCode {
    return items.hashCode ^
        currentPage.hashCode ^
        totalPages.hashCode ^
        totalItems.hashCode ^
        hasNextPage.hashCode;
  }
}
