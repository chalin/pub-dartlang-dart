// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:gcloud/db.dart';
import 'package:pub_dartlang_org/models.dart';

import 'tools_common.dart';

main(List<String> arguments) async {
  if (arguments.length < 2 || (
      !(arguments.length == 2 && arguments[0] == 'list') &&
      !(arguments.length == 3))) {
    print('Usage:');
    print('   ${Platform.script} list   <package>');
    print('   ${Platform.script} add    <package> <email-to-add>');
    print('   ${Platform.script} remove <package> <email-to-add>');
    exit(1);
  }

  String command = arguments[0];
  String package = arguments[1];
  String uploader = arguments.length == 3 ? arguments[2] : null;

  await withProdServices(() async {
    if (command == 'list') {
      await listUploaders(package);
    } else if (command == 'add') {
      await addUploader(package, uploader);
    } else if (command == 'remove') {
      await removeUploader(package, uploader);
    }
  });

  // TODO(kustermann): Remove this after Issue 61 is fixed.
  exit(0);
}

Future listUploaders(String packageName) async {
  return dbService.withTransaction((Transaction T) async {
    final Package package = (await T.lookup(
        [dbService.emptyKey.append(Package, id: packageName)])).first;
    if (package == null) {
      throw new Exception("Package $packageName does not exist.");
    }
    final uploaders = package.uploaderEmails;
    print('Current uploaders: $uploaders');
  });
}

Future addUploader(String packageName, String uploader) async {
  return dbService.withTransaction((Transaction T) async {
    Package package = (await T.lookup(
        [dbService.emptyKey.append(Package, id: packageName)])).first;
    if (package == null) {
      throw new Exception("Package $packageName does not exist.");
    }
    var uploaders = package.uploaderEmails;
    print('Current uploaders: $uploaders');
    if (uploaders.contains(uploader)) {
      throw new Exception('Uploader $uploader already exists');
    }
    package.uploaderEmails.add(uploader);
    T.queueMutations(inserts: [package]);
    await T.commit();
    print('Uploader $uploader added to list of uploaders');
  });
}

Future removeUploader(String packageName, String uploader) async {
  return dbService.withTransaction((Transaction T) async {
    Package package = (await T.lookup(
        [dbService.emptyKey.append(Package, id: packageName)])).first;
    if (package == null) {
      throw new Exception("Package $packageName does not exist.");
    }
    var uploaders = package.uploaderEmails;
    print('Current uploaders: $uploaders');
    if (!uploaders.contains(uploader)) {
      throw new Exception('Uploader $uploader does not exist');
    }
    package.uploaderEmails.remove(uploader);
    if (package.uploaderEmails.isEmpty) {
      throw new Exception('Would remove last uploader');
    }
    T.queueMutations(inserts: [package]);
    await T.commit();
    print('Uploader $uploader removed from list of uploaders');
  });
}
