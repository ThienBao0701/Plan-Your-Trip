package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.CouponDefinition;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface CouponDefinitionRepository extends JpaRepository<CouponDefinition, Long> {

    /** Case-insensitive claim-by-code lookup (codes are stored upper-case, input may be any case). */
    Optional<CouponDefinition> findByCodeIgnoreCase(String code);

    /** Case-insensitive uniqueness check for admin create/update. */
    boolean existsByCodeIgnoreCase(String code);

    /**
     * D4 — pessimistic write lock ({@code SELECT ... FOR UPDATE}) taken by every path that reads
     * {@code currentUsageCount}, decides against a limit, and then writes the counter back.
     *
     * <p>{@code totalUsageLimit} and {@code usageLimitPerUser} were enforced by a plain
     * read-check-write with no lock and no {@code @Version}, so two claims arriving together both
     * read the pre-increment count, both passed the check and both committed — the campaign issued
     * more discount than the operator authorised, silently. The counter is contended state in
     * exactly the way a loyalty balance or a night's inventory is, and it is guarded the same way:
     * see {@code LoyaltyAccountRepository#findByUserIdForUpdate},
     * {@code TravelCreditAccountRepository#findByUserIdForUpdate} and
     * {@code RoomInventoryRepository#lockForUpdate}.
     *
     * <p>Optimistic {@code @Version} was not used: adding a version column is a schema change, and
     * the established answer in this codebase for a contended counter is the row lock, which
     * serialises the two claims instead of failing the loser with a conflict it did not cause.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from CouponDefinition d where d.id = :id")
    Optional<CouponDefinition> findByIdForUpdate(@Param("id") Long id);

    /**
     * D4 — the locked counterpart of {@link #findByCodeIgnoreCase}, for the customer claim path.
     *
     * <p>Claiming must resolve the coupon by code AND lock it in one step. Looking it up unlocked
     * first and then locking by id does take the row lock, but Hibernate returns the instance
     * already in the persistence context rather than re-reading it, so the limit check runs against
     * the counter value loaded <em>before</em> the lock was granted — the lock is held and the read
     * is still stale, which is the harder half of the bug to see.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select d from CouponDefinition d where upper(d.code) = upper(:code)")
    Optional<CouponDefinition> findByCodeIgnoreCaseForUpdate(@Param("code") String code);
}
