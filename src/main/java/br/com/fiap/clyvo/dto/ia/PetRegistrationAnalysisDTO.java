package br.com.fiap.clyvo.dto.ia;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public record PetRegistrationAnalysisDTO(

        String especie,

        @JsonProperty("raca_estimada")
        String racaEstimada,

        @JsonProperty("cor_predominante")
        String corPredominante,

        @JsonProperty("porte_estimado")
        String porteEstimado,

        @JsonProperty("faixa_peso_estimada_kg")
        FaixaPesoDTO faixaPesoEstimadaKg,

        @JsonProperty("condicao_corporal")
        String condicaoCorporal,

        @JsonProperty("caracteristicas_visuais")
        List<String> caracteristicasVisuais,

        Double confianca

) {
}