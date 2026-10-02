package br.com.fiap.clyvo.dto;

public record VeterinarioAuthResponseDTO(
        Long id,
        String nome,
        String email,
        String crmv,
        String perfil,
        String token
) {
}