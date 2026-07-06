package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AuthDtos.UserDto;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.UserService;
import org.springframework.web.bind.annotation.*;

@RestController
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) { this.userService = userService; }

    @GetMapping("/api/me")
    public UserDto me(@AuthUser Long userId) {
        return userService.getCurrentUser(userId);
    }
}
