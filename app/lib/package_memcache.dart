// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_dartlang_org.package_memcache;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:memcache/memcache.dart';
import 'package:pub_server/shelf_pubserver.dart';

final Logger _logger = new Logger('pub.package_memcache');

/// Uses a [Memache] to set/get/invalidate metadata for packages.
class AppEnginePackageMemcache implements PackageCache {
  static const Duration EXPIRATION = const Duration(minutes: 60);
  static const String KEY_PREFIX = 'dart_package_json';

  final Memcache memcache;
  final String keyPrefix;

  AppEnginePackageMemcache(this.memcache, String namespace)
      : keyPrefix = (namespace == null || namespace.isEmpty)
          ? KEY_PREFIX : 'ns_${namespace}_$KEY_PREFIX';

  Future<List<int>> getPackageData(String package) async {
    var result =
        await _ignoreErrors(memcache.get(_packageKey(package), asBinary: true));

    if (result != null) _logger.info('memcache["$package"] found');
    else _logger.info('memcache["$package"] not found');

    return result;
  }

  Future setPackageData(String package, List<int> data) {
    _logger.info('memcache["$package"] setting to new data');
    return _ignoreErrors(
        memcache.set(_packageKey(package), data, expiration: EXPIRATION));
  }

  Future invalidatePackageData(String package) {
    _logger.info('memcache["$package"] invalidate entry');
    return _ignoreErrors(Future.wait([
        // TODO: Once the Python version is retired, we can remove this.
        memcache.remove('package_json_$package'),
        memcache.remove(_packageKey(package)),
    ]));
  }

  String _packageKey(String package) => '$keyPrefix$package';

  // We are ignoring any memcache errors and just return `null` in this case.
  //
  // NOTE: The worst what can happen is that up to `EXPIRATION` time passes
  // before a value gets automatically evicted from memcache
  //    => The duration for inconsistency is limited to 60 minutes ATM.
  Future _ignoreErrors(Future f) {
    return f.catchError((error, stackTrace) {
      _logger.warning(
          'Ignoring failed memcache API call (error: $error)',
          error, stackTrace);
    });
  }
}