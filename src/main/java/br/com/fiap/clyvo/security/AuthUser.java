package br.com.fiap.clyvo.security;

import br.com.fiap.clyvo.exception.AcessoNegadoException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;


@Component
public class AuthUser {

    private Jwt tokenAtual() {
        Authentication autenticacao =
                SecurityContextHolder.getContext().getAuthentication();

        if (autenticacao instanceof JwtAuthenticationToken tokenJwt) {
            return tokenJwt.getToken();
        }

        throw new AcessoNegadoException("Requisicao sem usuario autenticado.");
    }


    public Long getId() {
        Object claim = tokenAtual().getClaim("id");

        if (claim instanceof Number numero) {
            return numero.longValue();
        }

        throw new AcessoNegadoException("Token sem identificacao de usuario.");
    }


    public String getPerfil() {
        Object claim = tokenAtual().getClaim("role");
        return claim == null ? "" : claim.toString();
    }

    public boolean isTutor() {
        return "TUTOR".equals(getPerfil());
    }

    public boolean isVeterinario() {
        return "VETERINARIO".equals(getPerfil());
    }
}
