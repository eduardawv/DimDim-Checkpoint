package br.com.fiap.clyvo.security;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import org.springframework.core.io.Resource;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.converter.RsaKeyConverters;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter;

import org.springframework.security.web.SecurityFilterChain;

import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@EnableConfigurationProperties(SecurityConfig.RsaKeyProperties.class)
public class SecurityConfig {

    @ConfigurationProperties(prefix = "rsa")
    public record RsaKeyProperties(
            Resource publicKey,
            Resource privateKey
    ) {}

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        return http
                .authorizeHttpRequests(auth -> auth


                        .requestMatchers(HttpMethod.POST, "/api/tutores").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/tutores/login").permitAll()

                        .requestMatchers(HttpMethod.POST, "/api/veterinarios").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/veterinarios/login").permitAll()

                        // Swagger
                        .requestMatchers(
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                "/v3/api-docs/**"
                        ).permitAll()

                        .requestMatchers(HttpMethod.GET, "/api/tutores").hasRole("VETERINARIO")

                        .requestMatchers("/api/tutores/**").hasAnyRole("TUTOR", "VETERINARIO")


                        .requestMatchers("/api/veterinarios/**")
                        .hasRole("VETERINARIO")


                        .requestMatchers("/api/pets/**")
                        .hasAnyRole("TUTOR", "VETERINARIO")

                        .requestMatchers("/api/eventos/**")
                        .hasAnyRole("TUTOR", "VETERINARIO")


                        .requestMatchers("/api/ia/**")
                        .hasAnyRole("TUTOR", "VETERINARIO")

                        // Todo o restante exige login
                        .anyRequest().authenticated()
                )

                .csrf(csrf -> csrf.disable())

                .oauth2ResourceServer(oauth2 -> oauth2.jwt(
                        jwt -> jwt.jwtAuthenticationConverter(
                                jwtAuthenticationConverter()
                        )
                ))

                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    JwtDecoder jwtDecoder(RsaKeyProperties rsaKeyProperties) throws Exception {

        RSAPublicKey publicKey = RsaKeyConverters.x509()
                .convert(rsaKeyProperties.publicKey().getInputStream());

        return NimbusJwtDecoder
                .withPublicKey(publicKey)
                .build();
    }

    @Bean
    JwtEncoder jwtEncoder(RsaKeyProperties rsaKeyProperties) throws Exception {

        RSAPublicKey publicKey = RsaKeyConverters.x509()
                .convert(rsaKeyProperties.publicKey().getInputStream());

        RSAPrivateKey privateKey = RsaKeyConverters.pkcs8()
                .convert(rsaKeyProperties.privateKey().getInputStream());

        RSAKey rsaKey = new RSAKey.Builder(publicKey)
                .privateKey(privateKey)
                .build();

        return new NimbusJwtEncoder(
                new ImmutableJWKSet<>(
                        new JWKSet(rsaKey)
                )
        );
    }

    @Bean
    AuthenticationManager authenticationManager(
            AuthenticationConfiguration configuration
    ) throws Exception {

        return configuration.getAuthenticationManager();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {

        var authoritiesConverter =
                new JwtGrantedAuthoritiesConverter();

        authoritiesConverter.setAuthorityPrefix("ROLE_");

        authoritiesConverter.setAuthoritiesClaimName("role");

        var converter = new JwtAuthenticationConverter();

        converter.setJwtGrantedAuthoritiesConverter(
                authoritiesConverter
        );

        return converter;
    }
}
