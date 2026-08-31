package br.com.fiap.clyvo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record PetRequestDTO(
        @NotBlank(message = "O nome do pet é obrigatório")
        String nome,

        @NotBlank(message = "A espécie é obrigatória (ex: Cão, Gato)")
        String especie,

        String raca,

        @NotNull(message = "A idade é obrigatória")
        @Positive(message = "A idade não pode ser negativa")
        Integer idade,

        @NotNull(message = "O peso é obrigatório")
        @Positive(message = "O peso deve ser maior que zero")
        Double peso,

        @NotNull(message = "O ID do tutor responsável é obrigatório")
        Long tutorId
) {
}