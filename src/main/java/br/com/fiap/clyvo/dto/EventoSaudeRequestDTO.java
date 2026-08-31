package br.com.fiap.clyvo.dto;

import br.com.fiap.clyvo.model.enums.TipoEvento;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;

public record EventoSaudeRequestDTO(
        @NotNull Long petId,
        @NotNull TipoEvento tipoEvento,
        @NotBlank String descricao,
        @NotNull LocalDate dataEvento
) {}
