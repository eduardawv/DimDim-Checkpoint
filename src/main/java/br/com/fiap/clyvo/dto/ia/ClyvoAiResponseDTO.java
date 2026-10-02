package br.com.fiap.clyvo.dto.ia;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

public record ClyvoAiResponseDTO(

        String versao,

        PetAiDTO pet,

        @JsonProperty("score_saude")
        Integer scoreSaude,

        @JsonProperty("score_base_modelo")
        Integer scoreBaseModelo,

        @JsonProperty("penalidade_visual")
        Integer penalidadeVisual,

        @JsonProperty("status_saude")
        String statusSaude,

        String prioridade,

        @JsonProperty("fatores_risco")
        List<FatorRiscoDTO> fatoresRisco,

        @JsonProperty("probabilidades_modelo")
        Map<String, Double> probabilidadesModelo,

        String recomendacao,

        AlertaSaudeDTO alerta,

        @JsonProperty("processado_em")
        String processadoEm

) {
}