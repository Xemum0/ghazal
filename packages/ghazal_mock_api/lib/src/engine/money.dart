/// Integer-fils money helpers on `{fils, currency}` maps (ADR 0010 D6, half-up rounding per line). Port of engine/money.ts.
library;

import 'json.dart';

const currency = 'KWD';

Json fils(int n) => {'fils': n, 'currency': currency};

Json kd(num dinars) => fils(jsRound(dinars * 1000));

Json zero() => fils(0);

int filsOf(Json? m) => m == null ? 0 : (m['fils'] as num).toInt();

Json addMoney(Iterable<Json> ms) => fils(ms.fold(0, (s, m) => s + filsOf(m)));

Json subMoney(Json a, Json b) => fils(filsOf(a) - filsOf(b));

Json negMoney(Json a) => fils(filsOf(a) == 0 ? 0 : -filsOf(a));

Json mulMoney(Json a, int qty) => fils(filsOf(a) * qty);

/// Share in basis points, half-up: 30% of 18,200.000 = share(total, 3000).
Json shareMoney(Json a, int bps) => fils(floorDiv(filsOf(a) * bps + 5000, 10000));
