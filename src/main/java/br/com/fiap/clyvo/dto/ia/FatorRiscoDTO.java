package br.com.fiap.clyvo.dto.ia;

public record FatorRiscoDTO(
        String codigo,
        String origem,
        String severidade,
        String descricao
) {
}