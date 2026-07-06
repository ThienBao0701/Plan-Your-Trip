package com.example.planyourtrip.model;
import jakarta.persistence.*; import jakarta.validation.constraints.*; import java.time.LocalDate; import lombok.Getter; import lombok.Setter;
@Entity @Getter @Setter public class Trip { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @ManyToOne(optional=false) private User owner; @NotBlank private String title; @NotBlank private String destination; private String imageUrl; @NotNull private LocalDate startDate; @NotNull private LocalDate endDate; @Min(1) private int travelers; @DecimalMin("0.0") private double budget; }
