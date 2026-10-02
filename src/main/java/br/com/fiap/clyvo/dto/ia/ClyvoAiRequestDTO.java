package br.com.fiap.clyvo.dto.ia;

public record ClyvoAiRequestDTO(
        PetAiDTO pet,
        HistoricoSaudeDTO historico
) {
}