<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

## DAQ or darts_async_query

This package is a free interpretation of the react_query (or tanstack query, rtkq, etc.) concept in Flutter.

I'm gonna be honest - this is not my first try on creating a package like that, at some point I got tired of implementing all of the basic things and resorted to asking Cursor to create some basic models, functions, etc for me.

It's not a 100 percent tested solution, but I intend to use it on the projects that I'm working on - so the improvements and updates should be constant.

The package is based entirely on flutter_hooks, and, unfortunately, doesn't offer pure flutter alternatives at the moment.

## Usage guide

All of the queries use DAQ client that is provided via context - so to actually inject it you need to wrap the root application widget in the DAQProvider (with an optional configuration parameters) and after that you can use exported hooks in any HookWidget in your app.
