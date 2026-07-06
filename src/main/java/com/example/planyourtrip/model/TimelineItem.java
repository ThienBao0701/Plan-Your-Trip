package com.example.planyourtrip.model;
import jakarta.persistence.*; import jakarta.validation.constraints.*; import java.time.LocalTime; import lombok.Getter; import lombok.Setter;
@Entity @Getter @Setter public class TimelineItem { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @ManyToOne(optional=false) private Trip trip; @Min(1) private int dayNumber; @NotNull private LocalTime startTime; @NotNull private LocalTime endTime; @NotBlank private String title; @Column(length=1200) private String notes; @ManyToOne private Place place; }
