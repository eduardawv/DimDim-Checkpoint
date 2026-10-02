package br.com.fiap.clyvo.dto.ia;

import com.fasterxml.jackson.annotation.JsonProperty;

public record AlertaSaudeDTO(

        boolean necessario,

        String evento,

        String codigo,

        String prioridade,

        @JsonProperty("mensagem_sugerida")
        String mensagemSugerida

) {
}