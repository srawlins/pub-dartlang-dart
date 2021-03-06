// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_dartlang_org.atom_feed;

import 'dart:async';
import 'dart:convert';

import 'package:markdown/markdown.dart' as md;
import 'package:shelf/shelf.dart' as shelf;
import 'package:uuid/uuid.dart';

import '../../shared/urls.dart' show siteRoot;

import '../backend.dart';
import '../models.dart';

/// Handles requests for /feed.atom
Future<shelf.Response> atomFeedHandler(shelf.Request request) async {
  final int pageSize = 10;

  // The python version had paging support, but there was no point to it, since
  // the "next page" link was never returned to the caller.
  final int page = 1;

  final versions = await backend.latestPackageVersions(
      offset: pageSize * (page - 1), limit: pageSize);
  final feed = feedFromPackageVersions(request.requestedUri, versions);
  return atomXmlResponse(feed.toXmlDocument());
}

shelf.Response atomXmlResponse(String content, {int status = 200}) =>
    shelf.Response(
      status,
      body: content,
      headers: {
        'content-type': 'application/atom+xml; charset="utf-8"',
        'x-content-type-options': 'nosniff',
      },
    );

class FeedEntry {
  final String id;
  final String title;
  final DateTime updated;
  final List<String> authors;
  final String content;
  final String alternateUrl;
  final String alternateTitle;

  FeedEntry(this.id, this.title, this.updated, this.authors, this.content,
      this.alternateUrl, this.alternateTitle);

  void writeToXmlBuffer(StringBuffer buffer) {
    final escape = htmlEscape.convert;

    var authorTags = '';
    if (authors.isNotEmpty) {
      final escapedAuthors = authors.map(escape);
      authorTags = '<author><name>'
          '${escapedAuthors.join('</name></author><author><name>')}'
          '</name></author>';
    }

    buffer.writeln('''
        <entry>
          <id>urn:uuid:${escape(id)}</id>
          <title>${escape(title)}</title>
          <updated>${updated.toIso8601String()}</updated>
          $authorTags
          <content type="html">${escape(content)}</content>
          <link href="$alternateUrl"
                rel="alternate"
                title="$alternateTitle" />
        </entry>
      ''');
  }
}

class Feed {
  final String id;
  final String title;
  final String subTitle;
  final DateTime updated;
  final String author;
  final String alternateUrl;
  final String selfUrl;
  final String generator;
  final String generatorVersion;

  final List<FeedEntry> entries;

  Feed(
      this.id,
      this.title,
      this.subTitle,
      this.updated,
      this.author,
      this.alternateUrl,
      this.selfUrl,
      this.generator,
      this.generatorVersion,
      this.entries);

  String toXmlDocument() {
    final buffer = StringBuffer();
    buffer..writeln('<?xml version="1.0" encoding="UTF-8"?>');

    writeToXmlBuffer(buffer);
    return '$buffer';
  }

  void writeToXmlBuffer(StringBuffer buffer) {
    final escape = htmlEscape.convert;

    buffer.writeln('<feed xmlns="http://www.w3.org/2005/Atom">');

    buffer.writeln('''
        <id>$id</id>
        <title>${escape(title)}</title>
        <updated>${updated.toIso8601String()}</updated>
        <author>
          <name>${escape(author)}</name>
        </author>
        <link href="$alternateUrl" rel="alternate" />
        <link href="$selfUrl" rel="self" />
        <generator version="$generatorVersion">${escape(generator)}</generator>
        <subtitle>${escape(subTitle)}</subtitle>
        ''');

    for (var entry in entries) {
      entry.writeToXmlBuffer(buffer);
    }

    buffer.writeln('</feed>');
  }
}

Feed feedFromPackageVersions(Uri requestedUri, List<PackageVersion> versions) {
  final uuid = Uuid();

  // TODO: Remove this after the we moved the to the dart version of the app.
  final requestedUri = Uri.parse('$siteRoot/feed.atom');

  final entries = versions.map((PackageVersion version) {
    final url = requestedUri
        .resolve('/packages/${version.package}#${version.version}')
        .toString();
    final alternateUrl = requestedUri
        .resolve('/packages/${Uri.encodeComponent(version.package)}')
        .toString();
    final alternateTitle = version.package;

    final id = uuid.v5(Uuid.NAMESPACE_URL, url);
    final title = 'v${version.version} of ${version.package}';

    // NOTE: A pubspec.yaml file can have "author: ..." or "authors: ...".
    final List<String> authors = version.pubspec.authors;

    var content = 'No README Found';
    if (version.readme != null) {
      final filename = version.readme.filename;
      content = version.readme.text;
      if (filename.endsWith('.md')) {
        content = md.markdownToHtml(content);
      }
    }

    return FeedEntry(id as String, title, version.created, authors, content,
        alternateUrl, alternateTitle);
  }).toList();

  final id = requestedUri.resolve('/feed.atom').toString();
  final selfUrl = id;

  final title = 'Pub Packages for Dart';
  final subTitle = 'Last Updated Packages';
  final alternateUrl = requestedUri.resolve('/').toString();
  final author = 'Dart Team';
  final updated = DateTime.now().toUtc();

  return Feed(id, title, subTitle, updated, author, alternateUrl, selfUrl,
      'Pub Feed Generator', '0.1.0', entries);
}
