package com.example.planyourtrip.service;

import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RelatedEntityType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashSet;
import java.util.Set;

/**
 * RBAC R3a — mandatory owner security notifications (RBAC V1.1 §18 O-8, §20 FI-6, I25).
 *
 * <p>A separate class of notification: it is not stored in, read from or governed by {@code PartnerSettings},
 * so no setting and no role — including MANAGER through {@code settings.edit} — can switch it off. Recipients
 * are every ACTIVE owner (the primary owner and confirmed co-owners) and, where there is one, the member the
 * event is about. Channel: in-app (email once a production provider exists).
 *
 * <p>Written in the mutating transaction: an event that commits has its notifications, and a notification
 * that cannot be written rolls the event back.
 */
@Service
public class PartnerSecurityNotifier {

    private final NotificationService notifications;
    private final PartnerMembershipService memberships;

    public PartnerSecurityNotifier(NotificationService notifications, PartnerMembershipService memberships) {
        this.notifications = notifications;
        this.memberships = memberships;
    }

    /** Notifies every active owner of {@code company} and, when not null, the affected member. */
    @Transactional
    public void notifyOwners(PartnerProfile company, Long affectedUserId, String title, String message) {
        Set<Long> recipients = new LinkedHashSet<>(memberships.activeOwnerUserIds(company));
        if (affectedUserId != null) recipients.add(affectedUserId);
        for (Long recipient : recipients) {
            notifications.create(recipient, NotificationType.PARTNER, Priority.HIGH, title, message,
                RelatedEntityType.PARTNER, company.getId());
        }
    }
}
