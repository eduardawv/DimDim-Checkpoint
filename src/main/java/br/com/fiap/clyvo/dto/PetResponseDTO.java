package br.com.fiap.clyvo.dto;

public record PetResponseDTO(
        Long id,
        String nome,
        String especie,
        String raca,
        Integer idade,
        Double peso,
        Integer healthScore,
        Long tutorId
) {
}
