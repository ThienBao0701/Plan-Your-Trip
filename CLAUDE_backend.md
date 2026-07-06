# Plan Your Trip — Backend (Spring Boot)

## Project Overview
REST API cho "Plan Your Trip" — ứng dụng all-in-one lập kế hoạch du lịch.
Người dùng chọn điểm đến (tỉnh/thành/quận/huyện), khoảng ngày, số người;
app gợi ý 5 nhóm dịch vụ, cho phép xếp lịch trình theo ngày và theo dõi chi
tiêu thực tế tại từng điểm dừng.

## Tech Stack
- Language: Java
- Framework: Spring Boot (REST API)
- Data access: SQL thuần qua **JdbcTemplate** (hiện tại). Lộ trình: nâng cấp lên **Spring Data JPA**.
- Database: **SQL Server**
- AI (định hướng): **LangChain4j** trên Spring Boot gọi LLM (Gemini / OpenAI)
  để tự sinh lịch trình timeline trả về dạng JSON.

## Database Conventions (QUAN TRỌNG — Unicode tiếng Việt)
- Mọi cột lưu text tiếng Việt phải là **NVARCHAR** (không dùng VARCHAR).
- Collation: **Vietnamese_CI_AI** (case-insensitive, accent-insensitive) để
  tìm kiếm địa danh/địa điểm hoạt động được cả khi có dấu lẫn không dấu.
- Khi viết literal SQL có tiếng Việt, luôn prefix `N`: `N'Vũng Tàu'`.
- JDBC (mssql-jdbc): bật `sendStringParametersAsUnicode=true` trong connection
  string để bảo toàn Unicode.
- Luôn trả JSON encoding UTF-8.
- Luôn dùng **parameterized query** (PreparedStatement / named params) — vừa an
  toàn SQL injection, vừa tránh lỗi encoding khi nối chuỗi.

## Data Model (mô hình quan hệ)
- `locations` — địa danh hành chính (tỉnh / thành / quận / huyện)
- `categories` — 5 loại dịch vụ: Khách sạn, Khu vui chơi, Đồ ăn, Đồ uống, Chụp ảnh
- `places` — chi tiết địa điểm (thuộc 1 category + 1 location): địa chỉ, link
  Google Maps, khoảng giá, rating
- `place_menus` — món ăn / loại phòng / dịch vụ đi kèm của một place
- `trips` — chuyến đi: điểm đến, ngày đi/về, số người, tổng ngân sách
- `trip_timelines` — một điểm dừng đã xếp lịch: thuộc trip nào, ngày thứ mấy,
  khung giờ, place đến, và chi phí thực chi

Luồng quan hệ: `locations → categories → places → place_menus`;
`trips → trip_timelines`.

## API Conventions
- RESTful, request/response dạng JSON.
- Base path: `/api/v1` (điều chỉnh theo cấu hình thực tế của bạn).
- Dùng **DTO** cho request/response — không trả thẳng row DB ra ngoài.
- Cấu trúc error response thống nhất (ví dụ: { code, message, details }).
- Đặt tên field JSON nhất quán để frontend Flutter map đúng (xem CLAUDE.md frontend).

## Coding Guidelines
- Code sạch, logic rõ ràng, ưu tiên giải pháp từng bước.
- Theo phân tầng hiện có: **Controller → Service → Repository**.
- Khi thêm tính năng mới, giữ nguyên phong cách layering và cách xử lý Unicode ở trên.
