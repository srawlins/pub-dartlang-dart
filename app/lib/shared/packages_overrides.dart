// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// 'internal' packages are developed by the Dart team, and they are allowed to
/// point their URLs to *.dartlang.org (others would get a penalty for it).
const internalPackageNames = <String>[
  'angular',
  'angular_components',
];

final Set<String> knownMixedCasePackages = _knownMixedCasePackages.toSet();
final Set<String> blockedLowerCasePackages = _knownMixedCasePackages
    .map((s) => s.toLowerCase())
    .toSet()
      ..removeAll(_knownGoodLowerCasePackages);

const _knownMixedCasePackages = [
  'Autolinker',
  'Babylon',
  'DartDemoCLI',
  'FileTeCouch',
  'Flutter_Nectar',
  'Google_Search_v2',
  'LoadingBox',
  'PolymerIntro',
  'Pong',
  'RAL',
  'Transmission_RPC',
  'ViAuthClient',
];
const _knownGoodLowerCasePackages = [
  'babylon',
];

const redirectPackagePages = <String, String>{
  'flutter': 'https://pub.dartlang.org/flutter',
};

const redirectDartdocPages = <String, String>{
  'flutter': 'https://docs.flutter.io/',
};

// TODO: remove this after all of the flutter plugins have a proper issue tracker entry in their pubspec.yaml
const _issueTrackerUrlOverrides = <String, String>{
  'https://github.com/flutter/plugins/issues':
      'https://github.com/flutter/flutter/issues',
};

String overrideIssueTrackerUrl(String url) {
  if (url == null) {
    return null;
  }
  return _issueTrackerUrlOverrides[url] ?? url;
}

/// A package is soft-removed when we keep it in the archives and index, but we
/// won't serve the package or the documentation page, or any data about it.
bool isSoftRemoved(String packageName) =>
    redirectPackagePages.containsKey(packageName);
