package br.com.fiap.clyvo.dto.ia;

import com.fasterxml.jackson.annotation.JsonProperty;

public record HistoricoSaudeDTO(

        @JsonProperty("idade_anos")
        Integer idadeAnos,

        @JsonProperty("raca_predisposicao")
        Integer racaPredisposicao,

        @JsonProperty("dias_ultima_vacina")
        Integer diasUltimaVacina,

        @JsonProperty("dias_ultimo_vermifugo")
        Integer diasUltimoVermifugo,

        @JsonProperty("variacao_peso_iot")
        Integer variacaoPesoIot

) {
}