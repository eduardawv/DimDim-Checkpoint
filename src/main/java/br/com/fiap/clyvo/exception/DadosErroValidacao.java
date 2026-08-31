package br.com.fiap.clyvo.exception;

import org.springframework.validation.FieldError;

public record DadosErroValidacao(String campo, String mensagem) {

    // Construtor inteligente que já converte o erro do Spring para o nosso formato
    public DadosErroValidacao(FieldError erro) {
        this(erro.getField(), erro.getDefaultMessage());
    }
}