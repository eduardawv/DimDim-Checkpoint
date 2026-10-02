package br.com.fiap.clyvo.dto;

public record VeterinarioResponseDTO(
        Long id,
        String nome,
        String email,
        String crmv
) {
}