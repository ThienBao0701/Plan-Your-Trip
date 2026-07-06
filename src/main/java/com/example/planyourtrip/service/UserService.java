package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AuthDtos.UserDto;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserRepository users;

    public UserService(UserRepository users) { this.users = users; }

    public UserDto getCurrentUser(Long userId) {
        return users.findById(userId)
            .map(u -> new UserDto(u.getId(), u.getFullName(), u.getEmail(), u.getRole()))
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
    }
}
