package br.com.fiap.clyvo.repository;

import br.com.fiap.clyvo.model.Veterinario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface VeterinarioRepository extends JpaRepository<Veterinario, Long> {

    Optional<Veterinario> findByEmail(String email);

    Optional<Veterinario> findByCrmv(String crmv);
}