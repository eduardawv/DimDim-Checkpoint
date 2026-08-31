package br.com.fiap.clyvo.repository;

import br.com.fiap.clyvo.model.EventoSaude;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface EventoSaudeRepository extends JpaRepository<EventoSaude, Long> {
    Page<EventoSaude> findByPetIdOrderByDataEventoDesc(Long petId, Pageable paginacao);
}
