import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show PlatformConfig;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../voucher_fmt.dart';

/// The voucher terms, the one paragraph set the explainer needs and the diet allows behind an info glyph (web `Terms`): a short icon list,
/// every number from the platform configuration.
class VoucherTerms extends StatelessWidget {
  const VoucherTerms({required this.name, required this.replyHours, required this.config, super.key});

  final String name;
  final int replyHours;
  final PlatformConfig config;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final fee = f.moneyBrowse(config.voucherFeeFils);
    final confirm = f.digits(l.commonCountHours(config.confirmWindowHours));
    final rows = <(IconData, String)>[
      (GzIcons.ticket, l.clientVouchersTermWhat(fee, name)),
      (GzIcons.hall, l.clientVouchersTermDirect(name)),
      (GzIcons.timer, l.clientVouchersTermWindows(name, f.digits(l.commonCountHours(replyHours)), confirm)),
      (GzIcons.hourglass, l.clientVouchersTermValid(f.digits(l.commonCountDays(config.voucherValidityDays)))),
      (GzIcons.undo, l.clientVouchersTermBack(f.digits(l.commonCountDays(config.voucherReuseDays)))),
      (GzIcons.refresh, l.clientVouchersTermWithdraw),
      (GzIcons.warningCircle, l.clientVouchersTermForfeit(confirm)),
      (GzIcons.xCircle, l.clientVouchersTermUsed),
    ];
    return Column(
      key: const ValueKey<String>('voucher.terms'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: GzSize.disk,
                height: GzSize.disk,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceQuiet, shape: BoxShape.circle),
                child: ExcludeSemantics(child: GzIcon(rows[i].$1, size: GzIconSize.sm, color: c.iconSecondary)),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                  child: GzText(rows[i].$2, role: GzTextRole.body, color: c.textPrimary, figures: true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
