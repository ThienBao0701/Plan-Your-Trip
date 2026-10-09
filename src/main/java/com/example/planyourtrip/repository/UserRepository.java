package com.example.planyourtrip.repository;
import com.example.planyourtrip.model.User; import jakarta.persistence.LockModeType; import org.springframework.data.jpa.repository.JpaRepository; import org.springframework.data.jpa.repository.Lock; import org.springframework.data.jpa.repository.Query; import org.springframework.data.repository.query.Param; import java.util.Optional;
public interface UserRepository extends JpaRepository<User,Long>{ Optional<User> findByEmail(String email); boolean existsByEmail(String email);
    /** RBAC R6 — every account with the stored role {@code role}, by email (the admin access list, §25.4). */
    java.util.List<User> findByRoleOrderByEmailAsc(String role);
    /** Phase A — bootstrap duplicate guard: an address differing only in case is the same account. */
    boolean existsByEmailIgnoreCase(String email);
    /** Phase A — serialises one-time token issuance per account (cooldown and supersede must not race). */
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("SELECT u FROM User u WHERE u.id = :id") Optional<User> lockById(@Param("id") Long id);
}
