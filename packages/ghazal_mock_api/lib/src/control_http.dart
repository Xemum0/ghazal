/// `/__mock/*` over HTTP: the control surface for the standalone server and for dio-based Demo tools talking to the in-process adapter.
/// Not part of the OpenAPI contract. All commands are `POST` with a JSON body unless noted.
library;

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

import 'control.dart';
import 'core/problem.dart';
import 'engine/json.dart';
import 'core/app.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

shelf.Response _ok(Object? body) => shelf.Response.ok(jsonEncode(body ?? {'ok': true}), headers: _json);

shelf.Response _bad(String message, {int status = 400}) => shelf.Response(status, body: jsonEncode({'type': 'about:blank', 'title': message, 'status': status, 'code': status == 404 ? 'NOT_FOUND' : 'VALIDATION_FAILED', 'detail': message}), headers: {'content-type': 'application/problem+json'});

/// Handles a request when its path is under `/__mock/` (or `/v1/__mock/`); returns null for every other path.
Future<shelf.Response?> handleControl(MockApp app, MockControl control, shelf.Request request) async {
  var path = '/${request.url.path}';
  if (path.startsWith('/v1/__mock/')) path = path.substring(3);
  if (!path.startsWith('/__mock/')) return null;
  final parts = path.substring('/__mock/'.length).split('/').where((p) => p.isNotEmpty).toList();
  final method = request.method.toUpperCase();
  Json body = {};
  if (method != 'GET') {
    final text = await request.readAsString();
    if (text.isNotEmpty) {
      try {
        body = (jsonDecode(text) as Map).cast<String, dynamic>();
      } catch (_) {
        return _bad('invalid JSON body');
      }
    }
  }
  try {
    switch ((method, parts)) {
      case ('GET', ['state']):
        return _ok(control.state);
      case ('GET', ['outbox']):
        return _ok(control.outbox);
      case ('GET', ['events']):
        return _ok(control.events);
      case ('POST', ['reset']):
        await control.reset();
        return _ok(control.state);
      case ('POST', ['clock']):
        if (body['now'] is String) {
          control.setClock(DateTime.parse(body['now'] as String));
        } else {
          final ms = ((body['advanceDays'] as num?) ?? 0) * 86400000 + ((body['advanceHours'] as num?) ?? 0) * 3600000 + ((body['advanceMinutes'] as num?) ?? 0) * 60000 + ((body['advanceSeconds'] as num?) ?? 0) * 1000;
          if (ms == 0) return _bad('send {now} or advanceDays/advanceHours/advanceMinutes');
          control.advance(Duration(milliseconds: ms.toInt()));
        }
        return _ok({'now': control.nowText});
      case ('POST', ['session']):
        return _ok(control.sessionFor(body['persona'] as String? ?? 'reem'));
      case ('POST', ['persona']):
        return _ok({'persona': body['persona'], 'session': control.setPersona(body['persona'] as String? ?? 'guest')});
      case ('POST', ['scenario']):
        control.setScenario(body['scenario'] as String? ?? 'none');
        if (body['latencyMs'] != null) control.setLatency(Duration(milliseconds: (body['latencyMs'] as num).toInt()));
        return _ok(control.state);
      case ('POST', ['gateway']):
        control.setGatewayDown(body['down'] == true);
        return _ok(control.state);
      case ('POST', ['story']):
        control.jumpToStory(body['point'] as String? ?? 'pending');
        return _ok(control.state);
      case ('POST', ['rival']):
        return _ok({'booking': control.simulateRival()});
      case ('POST', ['flush']):
        await control.flush();
        return _ok(control.state);
      case ('POST', ['payments', final id, 'settle']):
        return _ok(control.settlePayment(id, outcome: body['outcome'] as String? ?? 'succeeded'));
      case ('POST', ['listings', final id, 'moderate']):
        return _ok(control.moderateListing(id, approve: body['action'] == 'approve', codes: ((body['codes'] as List?) ?? const []).cast<String>(), note: body['note'] as String?));
      case ('POST', ['plans', final cycle, 'rate']):
        control.setPlanRate(cycle, (body['ratesFils'] as num?)?.toInt());
        return _ok(control.state);
      case ('POST', ['listings', final id, 'billing']):
        return _ok(control.markListingPaid(id, amountFils: (body['amountFils'] as num?)?.toInt() ?? 0));
      case ('POST', ['support', 'refund-requests', final id, 'decide']):
        return _ok(control.decideRefund(id, grant: body['action'] == 'grant', reason: body['reason'] as String?));
      case ('POST', ['visits', final id, 'support-reply']):
        return _ok(control.supportReply(id, text: body['text'] as String?));
      case ('PUT', ['uploads', _]):
        return shelf.Response.ok('');
    }
  } on ApiError catch (e) {
    return shelf.Response(e.status, body: jsonEncode(e.toJson()), headers: {'content-type': 'application/problem+json'});
  } on ArgumentError catch (e) {
    return _bad(e.message.toString());
  }
  return _bad('unknown control endpoint ${request.method} $path', status: 404);
}
