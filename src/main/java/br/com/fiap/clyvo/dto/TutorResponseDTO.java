package br.com.fiap.clyvo.dto;

public record TutorResponseDTO(
        Long id,
        String nome,
        String email,
        String telefone
) {
}