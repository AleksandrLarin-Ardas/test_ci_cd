import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:test_ci_cd/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  await SentryFlutter.init((options) {
    options.dsn =
        'https://7f0d5c56121842239069c0ed6a2228c4@o4505510843645952.ingest.sentry.io/4505510845087744';
    options.tracesSampleRate = 1.0;
  }, appRunner: () => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: <NavigatorObserver>[
        observer,
      ],
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        analytics: analytics,
        observer: observer,
      ),
    );
  }
}

class _MetricHttpClient extends BaseClient {
  _MetricHttpClient(this._inner);

  final Client _inner;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Custom network monitoring is not supported for web.
    // https://firebase.google.com/docs/perf-mon/custom-network-traces?platform=android
    final HttpMetric metric = FirebasePerformance.instance
        .newHttpMetric(request.url.toString(), HttpMethod.Get);

    metric.requestPayloadSize = request.contentLength;
    await metric.start();

    StreamedResponse response;
    try {
      response = await _inner.send(request);
      print(
        'Called ${request.url} with custom monitoring, response code: ${response.statusCode}',
      );

      metric.responseContentType = 'text/html';
      metric.httpResponseCode = response.statusCode;
      metric.responsePayloadSize = response.contentLength;

      metric.putAttribute('score', '15');
      metric.putAttribute('to_be_removed', 'should_not_be_logged');
    } finally {
      metric.removeAttribute('to_be_removed');
      await metric.stop();
    }

    final attributes = metric.getAttributes();

    print('Http metric attributes: $attributes.');

    String? score = metric.getAttribute('score');
    print('Http metric score attribute value: $score');

    return response;
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.analytics,
    required this.observer,
  });

  final String title;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebasePerformance _performance = FirebasePerformance.instance;
  bool _isPerformanceCollectionEnabled = false;
  bool _trace1HasRan = false;
  bool _trace2HasRan = false;
  bool _customHttpMetricHasRan = false;
  @override
  void initState() {
    super.initState();
    startTransaction();
    _togglePerformanceCollection();
  }

  String _message = '';

  Future<void> _togglePerformanceCollection() async {
    // No-op for web.
    await _performance
        .setPerformanceCollectionEnabled(!_isPerformanceCollectionEnabled);

    // Always true for web.
    final bool isEnabled = await _performance.isPerformanceCollectionEnabled();
    setState(() {
      print('tapped');

      _isPerformanceCollectionEnabled = isEnabled;

    });
  }

  Future<void> _testTrace1() async {
    setState(() {
      _trace1HasRan = false;
    });

    final Trace trace = _performance.newTrace('test_trace_3');
    await trace.start();
    trace.putAttribute('favorite_color', 'blue');
    trace.putAttribute('to_be_removed', 'should_not_be_logged');

    trace.incrementMetric('sum', 200);
    trace.incrementMetric('total', 342);

    trace.removeAttribute('to_be_removed');
    await trace.stop();

    final sum = trace.getMetric('sum');
    print('test_trace_1 sum value: $sum');

    final attributes = trace.getAttributes();
    print('test_trace_1 attributes: $attributes');

    final favoriteColor = trace.getAttribute('favorite_color');
    print('test_trace_1 favorite_color: $favoriteColor');

    setState(() {
      _trace1HasRan = true;
    });
  }

  Future<void> _testTrace2() async {
    setState(() {
      _trace2HasRan = false;
    });

    final Trace trace = FirebasePerformance.instance.newTrace('test_trace_2');
    await trace.start();

    trace.setMetric('sum', 333);
    trace.setMetric('sum_2', 895);
    await trace.stop();

    final sum2 = trace.getMetric('sum');
    print('test_trace_2 sum value: $sum2');

    setState(() {
      _trace2HasRan = true;
    });
  }

  Future<void> _testCustomHttpMetric() async {
    setState(() {
      _customHttpMetricHasRan = false;
    });

    final _MetricHttpClient metricHttpClient = _MetricHttpClient(Client());

    final Request request = Request(
      'SEND',
      Uri.parse('https://www.bbc.co.uk'),
    );

    unawaited(metricHttpClient.send(request));

    setState(() {
      _customHttpMetricHasRan = true;
    });
    print(request.method);
  }

  Future<void> _testAutomaticHttpMetric() async {
    Response response = await get(Uri.parse('https://www.facebook.com'));
    print('Called facebook, response code: ${response.statusCode}');
  }

  void _incrementCounter() {
    throwError();

  }

  void crashApp() {
    FirebaseCrashlytics.instance.crash();
  }

  void throwError() async {
    await FirebaseCrashlytics.instance
        .recordError(Exception('test exception'), StackTrace.current,
            reason: 'a fatal error test',
            // Pass in 'fatal' argument
            fatal: true);

    await FirebaseCrashlytics.instance.recordError(
        Exception, StackTrace.current,
        reason: 'non-fatal error test', fatal: false);
    throw Exception();
  }

  void setMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  Future<void> _setDefaultEventParameters() async {
    if (kIsWeb) {
      setMessage(
        '"setDefaultEventParameters()" is not supported on web platform',
      );
    } else {
      // Only strings, numbers & null (longs & doubles for android, ints and doubles for iOS) are supported for default event parameters:
      await widget.analytics.setDefaultEventParameters(<String, dynamic>{
        'string': 'string',
        'int': 42,
        'long': 12345678910,
        'double': 42.0,
        'bool': true.toString(),
      });
      setMessage('setDefaultEventParameters succeeded');
    }
  }

  Future<void> _sendAnalyticsEvent() async {
    // Only strings and numbers (longs & doubles for android, ints and doubles for iOS) are supported for GA custom event parameters:
    // https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#+logeventwithname:parameters:
    // https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics#public-void-logevent-string-name,-bundle-params
    await widget.analytics.logEvent(
      name: 'test_event',
      parameters: <String, dynamic>{
        'string': 'string',
        'int': 42,
        'long': 12345678910,
        'double': 42.0,
        // Only strings and numbers (ints & doubles) are supported for GA custom event parameters:
        // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets#overview
        'bool': true.toString(),
      },
    );

    setMessage('logEvent succeeded');
  }

  Future<void> _testSetUserId() async {
    await widget.analytics.setUserId(id: 'some-user');
    setMessage('setUserId succeeded');
  }

  Future<void> _testSetCurrentScreen() async {
    await widget.analytics.setCurrentScreen(
      screenName: 'Analytics Demo',
      screenClassOverride: 'AnalyticsDemo',
    );
    setMessage('setCurrentScreen succeeded');
  }

  Future<void> _testSetAnalyticsCollectionEnabled() async {
    await widget.analytics.setAnalyticsCollectionEnabled(false);
    await widget.analytics.setAnalyticsCollectionEnabled(true);
    setMessage('setAnalyticsCollectionEnabled succeeded');
  }

  Future<void> _testSetSessionTimeoutDuration() async {
    await widget.analytics
        .setSessionTimeoutDuration(const Duration(milliseconds: 20000));
    setMessage('setSessionTimeoutDuration succeeded');
  }

  Future<void> _testSetUserProperty() async {
    await widget.analytics.setUserProperty(name: 'regular', value: 'indeed');
    setMessage('setUserProperty succeeded');
  }

  Future<void> _testAppInstanceId() async {
    String? id = await widget.analytics.appInstanceId;
    if (id != null) {
      setMessage('appInstanceId succeeded: $id');
    } else {
      setMessage('appInstanceId failed, consent declined');
    }
  }

  Future<void> _testResetAnalyticsData() async {
    await widget.analytics.resetAnalyticsData();
    setMessage('resetAnalyticsData succeeded');
  }

  AnalyticsEventItem itemCreator() {
    return AnalyticsEventItem(
      affiliation: 'affil',
      coupon: 'coup',
      creativeName: 'creativeName',
      creativeSlot: 'creativeSlot',
      discount: 2.22,
      index: 3,
      itemBrand: 'itemBrand',
      itemCategory: 'itemCategory',
      itemCategory2: 'itemCategory2',
      itemCategory3: 'itemCategory3',
      itemCategory4: 'itemCategory4',
      itemCategory5: 'itemCategory5',
      itemId: 'itemId',
      itemListId: 'itemListId',
      itemListName: 'itemListName',
      itemName: 'itemName',
      itemVariant: 'itemVariant',
      locationId: 'locationId',
      price: 9.99,
      currency: 'USD',
      promotionId: 'promotionId',
      promotionName: 'promotionName',
      quantity: 1,
    );
  }

  Future<void> _testAllEventTypes() async {
    await widget.analytics.logAddPaymentInfo();
    await widget.analytics.logAddToCart(
      currency: 'USD',
      value: 123,
      items: [itemCreator(), itemCreator()],
    );
    await widget.analytics.logAddToWishlist();
    await widget.analytics.logAppOpen();
    await widget.analytics.logBeginCheckout(
      value: 123,
      currency: 'USD',
      items: [itemCreator(), itemCreator()],
    );
    await widget.analytics.logCampaignDetails(
      source: 'source',
      medium: 'medium',
      campaign: 'campaign',
      term: 'term',
      content: 'content',
      aclid: 'aclid',
      cp1: 'cp1',
    );
    await widget.analytics.logEarnVirtualCurrency(
      virtualCurrencyName: 'bitcoin',
      value: 345.66,
    );

    await widget.analytics.logGenerateLead(
      currency: 'USD',
      value: 123.45,
    );
    await widget.analytics.logJoinGroup(
      groupId: 'test group id',
    );
    await widget.analytics.logLevelUp(
      level: 5,
      character: 'witch doctor',
    );
    await widget.analytics.logLogin(loginMethod: 'login');
    await widget.analytics.logPostScore(
      score: 1000000,
      level: 70,
      character: 'tiefling cleric',
    );
    await widget.analytics
        .logPurchase(currency: 'USD', transactionId: 'transaction-id');
    await widget.analytics.logSearch(
      searchTerm: 'hotel',
      numberOfNights: 2,
      numberOfRooms: 1,
      numberOfPassengers: 3,
      origin: 'test origin',
      destination: 'test destination',
      startDate: '2015-09-14',
      endDate: '2015-09-16',
      travelClass: 'test travel class',
    );
    await widget.analytics.logSelectContent(
      contentType: 'test content type',
      itemId: 'test item id',
    );
    await widget.analytics.logSelectPromotion(
      creativeName: 'promotion name',
      creativeSlot: 'promotion slot',
      items: [itemCreator()],
      locationId: 'United States',
    );
    await widget.analytics.logSelectItem(
      items: [itemCreator(), itemCreator()],
      itemListName: 't-shirt',
      itemListId: '1234',
    );
    await widget.analytics.logScreenView(
      screenName: 'tabs-page',
    );
    await widget.analytics.logViewCart(
      currency: 'USD',
      value: 123,
      items: [itemCreator(), itemCreator()],
    );
    await widget.analytics.logShare(
      contentType: 'test content type',
      itemId: 'test item id',
      method: 'facebook',
    );
    await widget.analytics.logSignUp(
      signUpMethod: 'test sign up method',
    );
    await widget.analytics.logSpendVirtualCurrency(
      itemName: 'test item name',
      virtualCurrencyName: 'bitcoin',
      value: 34,
    );
    await widget.analytics.logViewPromotion(
      creativeName: 'promotion name',
      creativeSlot: 'promotion slot',
      items: [itemCreator()],
      locationId: 'United States',
      promotionId: '1234',
      promotionName: 'big sale',
    );
    await widget.analytics.logRefund(
      currency: 'USD',
      value: 123,
      items: [itemCreator(), itemCreator()],
    );
    await widget.analytics.logTutorialBegin();
    await widget.analytics.logTutorialComplete();
    await widget.analytics.logUnlockAchievement(id: 'all Firebase API covered');
    await widget.analytics.logViewItem(
      currency: 'usd',
      value: 1000,
      items: [itemCreator()],
    );
    await widget.analytics.logViewItemList(
      itemListId: 't-shirt-4321',
      itemListName: 'green t-shirt',
      items: [itemCreator()],
    );
    await widget.analytics.logViewSearchResults(
      searchTerm: 'test search term',
    );
    setMessage('All standard events logged successfully');
  }

  Future<void> startTransaction() async {
    final transaction = Sentry.startTransaction('processOrderBatch()', 'task');

    try {
      await processOrderBatch(transaction);
    } catch (exception) {
      transaction.throwable = exception;
      transaction.status = SpanStatus.internalError();
    } finally {
      await transaction.finish();
    }
  }

  Future<void> processOrderBatch(ISentrySpan span) async {
    // span operation: task, span description: operation
    final innerSpan = span.startChild('task', description: 'operation');

    try {
      // omitted code
    } catch (exception) {
      innerSpan.throwable = exception;
      innerSpan.status = const SpanStatus.notFound();
    } finally {
      await innerSpan.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(color: Colors.lightGreenAccent, fontSize: 25);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              
              MaterialButton(
                onPressed: _sendAnalyticsEvent,
                child: const Text('Test logEvent'),
              ),
              MaterialButton(
                onPressed: _testAllEventTypes,
                child: const Text('Test standard event types'),
              ),
              MaterialButton(
                onPressed: _testSetUserId,
                child: const Text('Test setUserId'),
              ),
              MaterialButton(
                onPressed: _testSetCurrentScreen,
                child: const Text('Test setCurrentScreen'),
              ),
              MaterialButton(
                onPressed: _testSetAnalyticsCollectionEnabled,
                child: const Text('Test setAnalyticsCollectionEnabled'),
              ),
              MaterialButton(
                onPressed: _testSetSessionTimeoutDuration,
                child: const Text('Test setSessionTimeoutDuration'),
              ),
              MaterialButton(
                onPressed: _testSetUserProperty,
                child: const Text('Test setUserProperty'),
              ),
              MaterialButton(
                onPressed: _testAppInstanceId,
                child: const Text('Test appInstanceId'),
              ),
              MaterialButton(
                onPressed: _testResetAnalyticsData,
                child: const Text('Test resetAnalyticsData'),
              ),
              MaterialButton(
                onPressed: _setDefaultEventParameters,
                child: const Text('Test setDefaultEventParameters'),
              ),
              Text(
                _message,
                style: const TextStyle(color: Color.fromARGB(255, 0, 155, 0)),
              ),
              SizedBox(
                height: 40,
              ),
              ElevatedButton(
                onPressed: _testTrace1,
                child: const Text('Run Trace One'),
              ),
              Text(
                _trace1HasRan ? 'Trace Ran!' : '',
                style: textStyle,
              ),
              ElevatedButton(
                onPressed: _testTrace2,
                child: const Text('Run Trace Two'),
              ),
              Text(
                _trace2HasRan ? 'Trace Ran!' : '',
                style: textStyle,
              ),
              ElevatedButton(
                onPressed: _testCustomHttpMetric,
                child: const Text('Run Custom HttpMetric'),
              ),
              Text(
                _customHttpMetricHasRan ? 'Custom HttpMetric Ran!' : '',
                style: textStyle,
              ),
              ElevatedButton(
                onPressed: _testAutomaticHttpMetric,
                child: const Text('Run Automatic HttpMetric'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
