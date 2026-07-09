package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanTimelineDto.TripTimelineItemResponse;
import com.example.planyourtrip.dto.TripPlanTimelineDto.TripTimelineResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDayRepository;
import com.example.planyourtrip.repository.TripPlanDocumentRepository;
import com.example.planyourtrip.repository.TripPlanItemRepository;
import com.example.planyourtrip.repository.TripPlanReminderRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Read-only aggregate view merging {@link TripPlanDay}, {@link TripPlanItem},
 * {@link TripPlanDocument} and {@link TripPlanReminder} into one date-ordered
 * timeline. No new state — every entry is derived from an existing repository
 * query, and this service never mutates anything.
 *
 * <p>Entries without a real date to sort by (a day with no {@code date}, an item
 * on such a day, or a document with no day/item link and no fallback timestamp)
 * are simply omitted rather than given a fabricated position.
 */
@Service
public class TripTimelineService {

    private final TripPlanRepository tripRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final TripPlanDocumentRepository documentRepo;
    private final TripPlanReminderRepository reminderRepo;

    public TripTimelineService(TripPlanRepository tripRepo,
                                TripPlanCollaboratorRepository collaboratorRepo,
                                TripPlanDayRepository dayRepo,
                                TripPlanItemRepository itemRepo,
                                TripPlanDocumentRepository documentRepo,
                                TripPlanReminderRepository reminderRepo) {
        this.tripRepo = tripRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.documentRepo = documentRepo;
        this.reminderRepo = reminderRepo;
    }

    @Transactional(readOnly = true)
    public TripTimelineResponse getTimeline(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        List<TripTimelineItemResponse> items = new ArrayList<>();

        for (TripPlanDay day : dayRepo.findByTripPlanIdOrderByDayNumberAsc(trip.getId())) {
            if (day.getDate() == null) continue;

            String dayTitle = "Day " + day.getDayNumber() + (day.getTitle() != null ? ": " + day.getTitle() : "");
            items.add(new TripTimelineItemResponse("DAY", day.getDate(), null, day.getId(),
                dayTitle, day.getNotes(), day.getId(), null));

            for (TripPlanItem item : itemRepo.findByTripPlanDayIdOrderBySortOrderAsc(day.getId())) {
                String title = item.getPlace() != null ? item.getPlace().getName() : item.getCustomTitle();
                items.add(new TripTimelineItemResponse("ITEM", day.getDate(), item.getStartTime(), item.getId(),
                    title, item.getCustomDescription(), day.getId(), null));
            }
        }

        for (TripPlanDocument document : documentRepo.findByTripPlanIdOrderByPinnedDescCreatedAtDesc(trip.getId())) {
            LocalDate date;
            LocalTime time;
            Long tripDayId;

            if (document.getTripDay() != null && document.getTripDay().getDate() != null) {
                date = document.getTripDay().getDate();
                time = null;
                tripDayId = document.getTripDay().getId();
            } else if (document.getTripItem() != null
                    && document.getTripItem().getTripPlanDay().getDate() != null) {
                date = document.getTripItem().getTripPlanDay().getDate();
                time = document.getTripItem().getStartTime();
                tripDayId = document.getTripItem().getTripPlanDay().getId();
            } else {
                ZonedDateTime uploaded = document.getCreatedAt().atZone(ZoneId.systemDefault());
                date = uploaded.toLocalDate();
                time = uploaded.toLocalTime();
                tripDayId = null;
            }

            String title = document.getTitle() != null ? document.getTitle() : document.getDocumentType().name();
            items.add(new TripTimelineItemResponse("DOCUMENT", date, time, document.getId(),
                title, document.getNotes(), tripDayId, null));
        }

        for (TripPlanReminder reminder : reminderRepo.findByTripPlanIdOrderByReminderAtAsc(trip.getId())) {
            if (reminder.getStatus() == TripPlanReminderStatus.CANCELLED) continue;

            ZonedDateTime remindAt = reminder.getReminderAt().atZone(ZoneId.systemDefault());
            Long tripDayId = reminder.getTripDay() != null ? reminder.getTripDay().getId() : null;
            items.add(new TripTimelineItemResponse("REMINDER", remindAt.toLocalDate(), remindAt.toLocalTime(),
                reminder.getId(), reminder.getTitle(), reminder.getMessage(), tripDayId, reminder.getStatus().name()));
        }

        items.sort(Comparator.comparing(TripTimelineItemResponse::date)
            .thenComparing(i -> i.time() == null ? LocalTime.MIN : i.time()));

        return new TripTimelineResponse(trip.getId(), items);
    }

    // ── Permission helpers (duplicated from TripPlannerService by convention) ──

    private TripPlan viewableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return trip;
    }

    private boolean canView(TripPlan trip, Long userId) {
        if (trip.getUser().getId().equals(userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .map(TripPlanCollaborator::isActive).orElse(false);
    }
}
