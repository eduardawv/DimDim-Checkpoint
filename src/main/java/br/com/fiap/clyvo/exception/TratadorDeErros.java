package br.com.fiap.clyvo.exception;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;

@RestControllerAdvice
public class TratadorDeErros {

    // 1. Trata os erros do Bean Validation (@NotBlank, @NotNull, @Email, etc)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<List<DadosErroValidacao>> tratarErro400(MethodArgumentNotValidException ex) {
        // Pega todos os erros gerados pelo @Valid
        var erros = ex.getFieldErrors();

        // Mapeia para o nosso Record e devolve com Status 400 (Bad Request)
        return ResponseEntity.badRequest().body(erros.stream().map(DadosErroValidacao::new).toList());
    }

    // 2. Trata as nossas regras de negócio (ex: "Tutor não encontrado" lá no PetService)
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<String> tratarErroRegraDeNegocio(RuntimeException ex) {
        return ResponseEntity.badRequest().body("Erro: " + ex.getMessage());
    }
}
