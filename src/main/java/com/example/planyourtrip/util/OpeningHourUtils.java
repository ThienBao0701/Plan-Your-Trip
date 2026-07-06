package com.example.planyourtrip.util;

import com.example.planyourtrip.dto.PlaceDetailResponse.OpeningHourGroupResponse;
import com.example.planyourtrip.model.PlaceOpeningHour;

import java.time.LocalTime;
import java.util.*;

public final class OpeningHourUtils {

    private static final String[] DAY_NAMES =
        {"", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};

    private OpeningHourUtils() {}

    /**
     * Returns true if the place is currently open.
     * nowDayOfWeek follows ISO-8601: 1=Monday … 7=Sunday.
     * Handles overnight hours where closeTime < openTime (spans midnight).
     */
    public static boolean isOpenNow(List<PlaceOpeningHour> hours, LocalTime nowTime, int nowDayOfWeek) {
        if (hours == null || hours.isEmpty()) return false;

        PlaceOpeningHour today = hours.stream()
            .filter(h -> h.getDayOfWeek() == nowDayOfWeek)
            .findFirst()
            .orElse(null);

        if (today == null || today.isClosed()) return false;

        LocalTime open = today.getOpenTime();
        LocalTime close = today.getCloseTime();
        if (open == null || close == null) return false;

        if (close.isBefore(open)) {
            // Overnight: open from `open` until `close` next day
            return !nowTime.isBefore(open) || nowTime.isBefore(close);
        }
        return !nowTime.isBefore(open) && nowTime.isBefore(close);
    }

    /**
     * Groups consecutive days sharing the same schedule into human-readable ranges.
     * E.g. Mon–Fri 08:00–22:00, Sat–Sun 09:00–23:00.
     */
    public static List<OpeningHourGroupResponse> group(List<PlaceOpeningHour> rawHours) {
        if (rawHours == null || rawHours.isEmpty()) return List.of();

        List<PlaceOpeningHour> sorted = rawHours.stream()
            .sorted(Comparator.comparingInt(PlaceOpeningHour::getDayOfWeek))
            .toList();

        List<OpeningHourGroupResponse> groups = new ArrayList<>();
        PlaceOpeningHour seed = sorted.get(0);
        int startDay = seed.getDayOfWeek();
        int endDay   = startDay;
        LocalTime curOpen   = seed.getOpenTime();
        LocalTime curClose  = seed.getCloseTime();
        boolean   curClosed = seed.isClosed();

        for (int i = 1; i < sorted.size(); i++) {
            PlaceOpeningHour h = sorted.get(i);
            boolean consecutive  = h.getDayOfWeek() == endDay + 1;
            boolean sameSchedule = Objects.equals(h.getOpenTime(),  curOpen)
                                && Objects.equals(h.getCloseTime(), curClose)
                                && h.isClosed() == curClosed;

            if (consecutive && sameSchedule) {
                endDay = h.getDayOfWeek();
            } else {
                groups.add(makeGroup(startDay, endDay, curOpen, curClose, curClosed));
                startDay = endDay = h.getDayOfWeek();
                curOpen   = h.getOpenTime();
                curClose  = h.getCloseTime();
                curClosed = h.isClosed();
            }
        }
        groups.add(makeGroup(startDay, endDay, curOpen, curClose, curClosed));
        return groups;
    }

    private static OpeningHourGroupResponse makeGroup(
            int start, int end, LocalTime open, LocalTime close, boolean closed) {
        String days = (start == end)
            ? DAY_NAMES[start]
            : DAY_NAMES[start] + " - " + DAY_NAMES[end];
        return new OpeningHourGroupResponse(days, open, close, closed);
    }
}
