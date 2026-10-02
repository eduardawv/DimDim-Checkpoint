package br.com.fiap.clyvo.dto;

public record TutorAuthResponseDTO(
        Long id,
        String nome,
        String email,
        String perfil,
        String token
) {}