package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.security.rbac.AdminProfile;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

/** RBAC R6 — admin profile assignments (§28 M-5). Active means {@code revokedAt is null}. */
public interface AdminProfileAssignmentRepository extends JpaRepository<AdminProfileAssignment, Long> {

    /** The profiles the account holds now — read on every admin request, so a change applies on the next one. */
    @Query("select a.profile from AdminProfileAssignment a where a.user.id = :userId and a.revokedAt is null")
    List<AdminProfile> findActiveProfiles(@Param("userId") Long userId);

    @Query("select a from AdminProfileAssignment a where a.user.id = :userId and a.revokedAt is null")
    List<AdminProfileAssignment> findActiveByUserId(@Param("userId") Long userId);

    @Query("select a from AdminProfileAssignment a join fetch a.user where a.user.id in :userIds and a.revokedAt is null")
    List<AdminProfileAssignment> findActiveByUserIds(@Param("userIds") Collection<Long> userIds);

    /**
     * Every active assignment of {@code profile} held by an enabled {@code ADMIN} account, locked for the rest of
     * the transaction. Profile changes take these locks before counting, so two administrators revoking each
     * other's last {@code PLATFORM_OWNER} grant are serialised and the second sees the first (AP-2). A dual-control
     * approval takes the same locks to recheck its requester and approver, so a profile change cannot slip between
     * that check and the action. Rows are locked in id order, the same order for every caller.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from AdminProfileAssignment a where a.profile = :profile and a.revokedAt is null "
        + "and a.user.role = 'ADMIN' and a.user.enabled = true order by a.id")
    List<AdminProfileAssignment> lockActiveHoldersOf(@Param("profile") AdminProfile profile);
}
