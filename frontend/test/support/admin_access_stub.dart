import 'dart:convert';

import 'package:http/http.dart' as http;

/// Every active admin permission key a `PLATFORM_OWNER` receives from
/// `GET /api/admin/me/access` (RBAC V1.1 §9.2; the reserved A07, A11 and A12
/// are never listed).
const platformOwnerPermissions = <String>[
  'admin.console.access',
  'admin.access.manage',
  'admin.audit_log.view',
  'admin.analytics.view',
  'admin.customer.view',
  'admin.customer.wallet.view',
  'admin.partner.view',
  'admin.partner.verify',
  'admin.partner.suspend',
  'admin.place.view',
  'admin.place.edit',
  'admin.place.moderate',
  'admin.place.publish',
  'admin.place.owner.assign',
  'admin.room.edit',
  'admin.inventory.edit',
  'admin.rate.edit',
  'admin.media.manage',
  'admin.category.manage',
  'admin.amenity.manage',
  'admin.location.manage',
  'admin.booking.view',
  'admin.booking.operate',
  'admin.booking.override',
  'admin.booking.compensate',
  'admin.conversation.view',
  'admin.conversation.intervene',
  'admin.payment.view',
  'admin.payment.intervene',
  'admin.invoice.view',
  'admin.invoice.manage',
  'admin.review.view',
  'admin.review.moderate',
  'admin.promotion.manage',
  'admin.coupon.manage',
  'admin.gift_card.catalog.manage',
  'admin.gift_card.value.manage',
  'admin.customer_program.manage',
  'admin.customer.entitlement.adjust',
  'admin.travel_credit.adjust',
  'admin.personalization.manage',
  'admin.notification.broadcast',
  'admin.system_job.run',
];

/// The access document of a signed-in administrator holding [profiles] and
/// exactly [permissions].
Map<String, dynamic> adminAccessDocument({
  int userId = 1,
  List<String> profiles = const ['PLATFORM_OWNER'],
  List<String> permissions = platformOwnerPermissions,
}) =>
    {
      'userId': userId,
      'email': 'admin@planyourtrip.com',
      'fullName': 'Admin',
      'profiles': profiles,
      'permissions': permissions,
      'stepUp': {'freshUntil': null},
    };

/// Wraps [inner] so that `GET /api/admin/me/access` answers [document]
/// (a platform owner by default) and every other request reaches [inner]
/// unchanged. The access read never reaches [inner], so request logs and
/// request-count assertions written before RBAC R6 keep their meaning.
http.Client withAdminAccess(http.Client inner,
        {Map<String, dynamic>? document}) =>
    _AdminAccessClient(inner, document ?? adminAccessDocument());

class _AdminAccessClient extends http.BaseClient {
  final http.Client inner;
  final Map<String, dynamic> document;

  _AdminAccessClient(this.inner, this.document);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method == 'GET' &&
        request.url.path.endsWith('/admin/me/access')) {
      return Future.value(http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(document))),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      ));
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
