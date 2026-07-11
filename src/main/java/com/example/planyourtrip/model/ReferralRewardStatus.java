package com.example.planyourtrip.model;

/**
 * Phase 7.22 — Referral &amp; Invite Rewards.
 * Lifecycle of one referral relationship ({@link ReferralReward}). Deliberately
 * a two-state model — reward granting is ATOMIC with qualification detection, so
 * there is no distinct QUALIFIED-but-not-yet-REWARDED window to represent:
 * <ul>
 *   <li>{@code USED} — the invitee registered/entered the inviter's code and is
 *       awaiting their first qualifying completed booking. No value has been
 *       granted yet.</li>
 *   <li>{@code REWARDED} — a qualifying booking completed and BOTH the inviter's
 *       and invitee's configured rewards were granted atomically. Terminal; the
 *       one-way {@code USED → REWARDED} gate makes every later completion
 *       trigger a no-op, guaranteeing reward-once.</li>
 * </ul>
 */
public enum ReferralRewardStatus {
    USED,
    REWARDED
}
