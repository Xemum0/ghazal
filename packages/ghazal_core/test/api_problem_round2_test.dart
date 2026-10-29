// The two codes of the partner application (owner round 2, ADR 0038, PA-ACC-07): they parse from the wire, keep their wire strings and carry
// the params of the problem (the application status a guard screen reads).
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart';

void main() {
  test('APPLICATION_NOT_ACCEPTED and APPLICATION_NOT_EDITABLE parse, round-trip and have message keys', () {
    expect(ApiProblemCode.parse('APPLICATION_NOT_ACCEPTED'), ApiProblemCode.applicationNotAccepted);
    expect(ApiProblemCode.parse('APPLICATION_NOT_EDITABLE'), ApiProblemCode.applicationNotEditable);
    expect(ApiProblemCode.applicationNotAccepted.wire, 'APPLICATION_NOT_ACCEPTED');
    expect(ApiProblemCode.applicationNotEditable.wire, 'APPLICATION_NOT_EDITABLE');
    expect(ApiProblemCode.applicationNotAccepted.messageKey, 'apiErrorApplicationNotAccepted');
    expect(ApiProblemCode.applicationNotEditable.messageKey, 'apiErrorApplicationNotEditable');
  });

  test('a 403 problem body keeps the code and the application status in its params', () {
    final p = ApiProblem.fromResponse(
      status: 403,
      body: <String, Object?>{'status': 403, 'code': 'APPLICATION_NOT_ACCEPTED', 'params': <String, Object?>{'applicationStatus': 'pending'}},
    );
    expect(p.code, ApiProblemCode.applicationNotAccepted);
    expect(p.status, 403);
    expect(p.params['applicationStatus'], 'pending');
    final conflict = ApiProblem.fromResponse(status: 409, body: <String, Object?>{'code': 'APPLICATION_NOT_EDITABLE'});
    expect(conflict.code, ApiProblemCode.applicationNotEditable);
  });
}
