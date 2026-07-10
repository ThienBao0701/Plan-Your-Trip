package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.TravelCreditDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.CustomerProfileRepository;
import com.example.planyourtrip.repository.TravelCreditAccountRepository;
import com.example.planyourtrip.repository.TravelCreditTransactionRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * PROMOTIONAL PLATFORM CREDIT ONLY — no withdrawal, no transfer between users,
 * no cash conversion, no payment-provider integration, no financial credentials.
 * Customers have zero mutation endpoints: only the admin grant/deduct paths
 * (and the idempotent seed grant) ever change a balance.
 *
 * <p>Invariants enforced here:
 * <ul>
 *   <li>one account per user, created lazily on first access (default currency =
 *       customer profile's preferred currency when present, else "VND");</li>
 *   <li>balance never negative — a deduction that would overdraw is rejected
 *       with 409 CONFLICT (chosen over 400 to match {@code PromotionService}'s
 *       "state conflict" convention);</li>
 *   <li>every balance change inserts exactly one immutable
 *       {@link TravelCreditTransaction} carrying balanceBefore/balanceAfter —
 *       existing rows are never updated (all columns {@code updatable=false});</li>
 *   <li>amount is always &gt; 0; direction comes from the transaction type /
 *       endpoint (see {@link TravelCreditTransactionType});</li>
 *   <li>idempotency: a non-blank {@code idempotencyKey} is pre-checked
 *       ({@code findByIdempotencyKey} → return the original transaction, no
 *       second balance change) and backstopped by the DB unique constraint —
 *       the same two-layer pattern as Phase 7.13's reminder {@code sourceKey};</li>
 *   <li>concurrency: every mutation acquires a pessimistic write lock on the
 *       account row ({@code findByUserIdForUpdate}, SELECT ... FOR UPDATE)
 *       inside the @Transactional boundary, serializing concurrent mutations —
 *       chosen over optimistic @Version + retry for simplicity.</li>
 * </ul>
 */
@Service
public class TravelCreditService {

    private static final Set<TravelCreditTransactionType> INCREASE_TYPES =
        EnumSet.of(TravelCreditTransactionType.GRANT, TravelCreditTransactionType.PROMOTION,
                   TravelCreditTransactionType.REFUND_CREDIT, TravelCreditTransactionType.REVERSAL);
    private static final Set<TravelCreditTransactionType> DECREASE_TYPES =
        EnumSet.of(TravelCreditTransactionType.ADJUSTMENT, TravelCreditTransactionType.REDEMPTION,
                   TravelCreditTransactionType.EXPIRATION);

    private final TravelCreditAccountRepository accountRepo;
    private final TravelCreditTransactionRepository transactionRepo;
    private final UserRepository userRepo;
    private final CustomerProfileRepository profileRepo;
    private final NotificationService notificationService;

    public TravelCreditService(TravelCreditAccountRepository accountRepo,
                                TravelCreditTransactionRepository transactionRepo,
                                UserRepository userRepo,
                                CustomerProfileRepository profileRepo,
                                NotificationService notificationService) {
        this.accountRepo = accountRepo;
        this.transactionRepo = transactionRepo;
        this.userRepo = userRepo;
        this.profileRepo = profileRepo;
        this.notificationService = notificationService;
    }

    // ── Customer read paths ──────────────────────────────────────────────────

    /** Not readOnly — first access lazily creates the account. */
    @Transactional
    public TravelCreditAccountResponse getOrCreateMyAccount(Long userId) {
        return toAccountResponse(getOrCreateAccount(userId));
    }

    /**
     * Filtered/paginated in-stream like {@code TravelWalletService#list} —
     * every filter is optional. {@code from}/{@code to} are inclusive calendar
     * dates compared in the system zone.
     */
    @Transactional
    public PageResponse<TravelCreditTransactionResponse> myTransactions(Long userId, Integer page, Integer size,
                                                                          TravelCreditTransactionType type,
                                                                          LocalDate from, LocalDate to) {
        TravelCreditAccount account = getOrCreateAccount(userId);

        List<TravelCreditTransaction> all = transactionRepo
            .findByAccountIdOrderByCreatedAtDescIdDesc(account.getId()).stream()
            .filter(t -> type == null || t.getTransactionType() == type)
            .filter(t -> from == null || !txDate(t).isBefore(from))
            .filter(t -> to == null || !txDate(t).isAfter(to))
            .toList();

        int p = page != null ? Math.max(page, 0) : 0;
        int sz = size != null && size > 0 ? size : 20;
        int fromIdx = Math.min(p * sz, all.size());
        int toIdx = Math.min(fromIdx + sz, all.size());
        List<TravelCreditTransactionResponse> content =
            all.subList(fromIdx, toIdx).stream().map(this::toTransactionResponse).toList();

        return new PageResponse<>(content, p, sz, all.size(), (int) Math.ceil((double) all.size() / sz));
    }

    // ── Admin support view (strictly read-only — never creates the account) ─

    @Transactional(readOnly = true)
    public TravelCreditAdminViewResponse adminView(Long targetUserId) {
        userOrThrow(targetUserId);
        return accountRepo.findByUserId(targetUserId)
            .map(account -> new TravelCreditAdminViewResponse(
                targetUserId,
                toAccountResponse(account),
                transactionRepo.findByAccountIdOrderByCreatedAtDescIdDesc(account.getId()).stream()
                    .limit(20).map(this::toTransactionResponse).toList()))
            .orElseGet(() -> new TravelCreditAdminViewResponse(targetUserId, null, List.of()));
    }

    // ── Admin mutations (customers can NEVER grant/deduct — no customer path) ─

    @Transactional
    public TravelCreditTransactionResponse grant(Long targetUserId, TravelCreditAdjustmentRequest req) {
        return mutate(targetUserId, req, true);
    }

    @Transactional
    public TravelCreditTransactionResponse deduct(Long targetUserId, TravelCreditAdjustmentRequest req) {
        return mutate(targetUserId, req, false);
    }

    private TravelCreditTransactionResponse mutate(Long targetUserId, TravelCreditAdjustmentRequest req,
                                                    boolean increase) {
        User user = userOrThrow(targetUserId);
        TravelCreditTransactionType txType = resolveType(req.transactionType(), increase);

        // Idempotency pre-check: replaying a key returns the original ledger row untouched.
        String idempotencyKey = req.idempotencyKey() != null && !req.idempotencyKey().isBlank()
            ? req.idempotencyKey().trim() : null;
        if (idempotencyKey != null) {
            var existing = transactionRepo.findByIdempotencyKey(idempotencyKey);
            if (existing.isPresent()) return toTransactionResponse(existing.get());
        }

        BigDecimal amount = req.amount().setScale(2, RoundingMode.HALF_UP);
        if (amount.signum() <= 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "amount must be greater than zero");

        // Pessimistic write lock on the account row — see class javadoc.
        TravelCreditAccount account = accountRepo.findByUserIdForUpdate(targetUserId)
            .orElseGet(() -> accountRepo.save(newAccount(user)));

        if (!account.getCurrency().equalsIgnoreCase(req.currency().trim()))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Currency mismatch: account currency is " + account.getCurrency());

        BigDecimal before = account.getBalance();
        BigDecimal after;
        if (increase) {
            after = before.add(amount);
        } else {
            if (before.compareTo(amount) < 0)
                throw new ApiException(HttpStatus.CONFLICT,
                    "Insufficient travel credit balance: balance " + before.toPlainString()
                        + ", requested deduction " + amount.toPlainString());
            after = before.subtract(amount);
        }

        TravelCreditTransaction tx = new TravelCreditTransaction();
        tx.setAccount(account);
        tx.setTransactionType(txType);
        tx.setAmount(amount);
        tx.setBalanceBefore(before);
        tx.setBalanceAfter(after);
        tx.setDescription(req.description());
        tx.setReferenceType(req.referenceType());
        tx.setReferenceId(req.referenceId());
        tx.setIdempotencyKey(idempotencyKey);
        tx.setExpiresAt(req.expiresAt());
        TravelCreditTransaction saved = transactionRepo.save(tx);

        account.setBalance(after);
        accountRepo.save(account);

        if (increase) {
            // Deliberately only amount + currency — req.description() is an internal
            // admin note and must never leak into the user-facing message.
            notificationService.create(targetUserId, NotificationType.PAYMENT, Priority.NORMAL,
                "Travel credits added",
                amount.toPlainString() + " " + account.getCurrency()
                    + " in promotional travel credits has been added to your account.",
                RelatedEntityType.SYSTEM, saved.getId());
        }

        return toTransactionResponse(saved);
    }

    private TravelCreditTransactionType resolveType(TravelCreditTransactionType requested, boolean increase) {
        if (requested == null)
            return increase ? TravelCreditTransactionType.GRANT : TravelCreditTransactionType.ADJUSTMENT;
        Set<TravelCreditTransactionType> allowed = increase ? INCREASE_TYPES : DECREASE_TYPES;
        if (!allowed.contains(requested))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "transactionType " + requested + " is not valid for a "
                    + (increase ? "grant" : "deduction") + " — allowed: " + allowed);
        return requested;
    }

    // ── Account helpers ──────────────────────────────────────────────────────

    private TravelCreditAccount getOrCreateAccount(Long userId) {
        return accountRepo.findByUserId(userId)
            .orElseGet(() -> accountRepo.save(newAccount(userOrThrow(userId))));
    }

    private TravelCreditAccount newAccount(User user) {
        TravelCreditAccount account = new TravelCreditAccount();
        account.setUser(user);
        account.setBalance(BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY));
        account.setCurrency(defaultCurrency(user.getId()));
        return account;
    }

    private String defaultCurrency(Long userId) {
        return profileRepo.findByUserId(userId)
            .map(CustomerProfile::getPreferredCurrency)
            .filter(c -> c != null && !c.isBlank())
            .orElse("VND");
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    private LocalDate txDate(TravelCreditTransaction t) {
        return t.getCreatedAt().atZone(ZoneId.systemDefault()).toLocalDate();
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TravelCreditAccountResponse toAccountResponse(TravelCreditAccount a) {
        return new TravelCreditAccountResponse(
            a.getId(), a.getUser().getId(), a.getBalance(), a.getCurrency(),
            a.getCreatedAt(), a.getUpdatedAt()
        );
    }

    private TravelCreditTransactionResponse toTransactionResponse(TravelCreditTransaction t) {
        return new TravelCreditTransactionResponse(
            t.getId(), t.getAccount().getId(), t.getTransactionType(),
            t.getAmount(), t.getBalanceBefore(), t.getBalanceAfter(),
            t.getDescription(), t.getReferenceType(), t.getReferenceId(),
            t.getIdempotencyKey(), t.getExpiresAt(), t.getCreatedAt()
        );
    }
}
