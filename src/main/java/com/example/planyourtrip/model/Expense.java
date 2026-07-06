package com.example.planyourtrip.model;
import jakarta.persistence.*; import jakarta.validation.constraints.*; import java.time.LocalDate; import lombok.Getter; import lombok.Setter;
@Entity @Getter @Setter public class Expense { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id; @ManyToOne(optional=false) private Trip trip; @NotBlank private String title; @NotBlank private String category; @DecimalMin("0.0") private double amount; @NotNull private LocalDate date; }
