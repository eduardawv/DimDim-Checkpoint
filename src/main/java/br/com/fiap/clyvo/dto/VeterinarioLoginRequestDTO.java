package br.com.fiap.clyvo.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record VeterinarioLoginRequestDTO(
        @NotBlank @Email String email,
        @NotBlank String senha
) {
}