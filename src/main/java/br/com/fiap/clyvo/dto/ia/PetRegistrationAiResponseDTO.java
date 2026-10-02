package br.com.fiap.clyvo.dto.ia;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PetRegistrationAiResponseDTO(

        String origem,

        @JsonProperty("requer_confirmacao")
        Boolean requerConfirmacao,

        @JsonProperty("analise_cadastro")
        PetRegistrationAnalysisDTO analiseCadastro,

        String aviso

) {
}