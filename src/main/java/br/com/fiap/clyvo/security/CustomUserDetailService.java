package br.com.fiap.clyvo.security;

import br.com.fiap.clyvo.model.Tutor;
import br.com.fiap.clyvo.model.Veterinario;
import br.com.fiap.clyvo.repository.TutorRepository;
import br.com.fiap.clyvo.repository.VeterinarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class CustomUserDetailService implements UserDetailsService {

    @Autowired
    private TutorRepository tutorRepository;

    @Autowired
    private VeterinarioRepository veterinarioRepository;

    @Override
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {

        Tutor tutor = tutorRepository.findByEmail(email).orElse(null);

        if (tutor != null) {
            return new CustomUserDetails(
                    tutor.getId(),
                    tutor.getNome(),
                    tutor.getEmail(),
                    tutor.getSenha(),
                    "TUTOR"
            );
        }

        Veterinario veterinario =
                veterinarioRepository.findByEmail(email).orElse(null);

        if (veterinario != null) {
            return new CustomUserDetails(
                    veterinario.getId(),
                    veterinario.getNome(),
                    veterinario.getEmail(),
                    veterinario.getSenha(),
                    "VETERINARIO"
            );
        }

        throw new UsernameNotFoundException(
                "Usuário não encontrado: " + email
        );
    }
}