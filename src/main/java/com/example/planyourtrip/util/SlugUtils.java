package com.example.planyourtrip.util;

import java.text.Normalizer;

public final class SlugUtils {
    private SlugUtils() {}

    public static String toSlug(String text) {
        if (text == null || text.isBlank()) return null;
        // Pre-substitute Đ/đ which does not decompose in NFD
        String s = text.replace("Đ", "D").replace("đ", "d");
        String nfd = Normalizer.normalize(s, Normalizer.Form.NFD);
        String ascii = nfd.replaceAll("[^\\p{ASCII}]", "");
        return ascii.toLowerCase()
            .replaceAll("[^a-z0-9\\s-]", "")
            .trim()
            .replaceAll("\\s+", "-");
    }

    public static String normalize(String text) {
        if (text == null || text.isBlank()) return "";
        // Pre-substitute Đ/đ which does not decompose in NFD
        String s = text.replace("Đ", "D").replace("đ", "d");
        String nfd = Normalizer.normalize(s, Normalizer.Form.NFD);
        return nfd.replaceAll("[^\\p{ASCII}]", "").toLowerCase().trim();
    }
}
