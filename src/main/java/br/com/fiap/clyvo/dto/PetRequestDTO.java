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

        // ALTERADO - Sprint 4: deixou de ser obrigatorio.
        // Quando quem cadastra e um TUTOR, este campo e IGNORADO e o dono do pet
        // passa a ser o tutor do token. O campo continua existindo para nao quebrar
        // o app mobile, que ja envia esse JSON, e para o fluxo do VETERINARIO,
        // que precisa informar de qual tutor e o pet.
        Long tutorId
) {
}
