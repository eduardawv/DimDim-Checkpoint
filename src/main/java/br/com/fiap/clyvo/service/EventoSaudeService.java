package br.com.fiap.clyvo.service;

import br.com.fiap.clyvo.dto.EventoSaudeRequestDTO;
import br.com.fiap.clyvo.dto.EventoSaudeResponseDTO;
import br.com.fiap.clyvo.model.EventoSaude;
import br.com.fiap.clyvo.model.Pet;
import br.com.fiap.clyvo.repository.EventoSaudeRepository;
import br.com.fiap.clyvo.repository.PetRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EventoSaudeService {

    @Autowired
    private EventoSaudeRepository repository;

    @Autowired
    private PetRepository petRepository;

    @Transactional
    public EventoSaudeResponseDTO cadastrarEvento(EventoSaudeRequestDTO dto) {
        Pet pet = petRepository.findById(dto.petId())
                .orElseThrow(() -> new RuntimeException("Pet não encontrado com o ID: " + dto.petId()));

        EventoSaude evento = new EventoSaude();
        evento.setPet(pet);
        evento.setTipoEvento(dto.tipoEvento());
        evento.setDescricao(dto.descricao());
        evento.setDataEvento(dto.dataEvento());

        int novoScore = dto.tipoEvento().calcularNovoScore(pet.getHealthScore());

        pet.setHealthScore(novoScore);
        petRepository.save(pet);

        evento = repository.save(evento);

        return new EventoSaudeResponseDTO(
                evento.getId(),
                pet.getId(),
                evento.getTipoEvento(),
                evento.getDescricao(),
                evento.getDataEvento(),
                pet.getHealthScore()
        );
    }

    @Transactional(readOnly = true)
    public Page<EventoSaudeResponseDTO> buscarEventosPorPet(Long petId, Pageable paginacao) {
        if (!petRepository.existsById(petId)) {
            throw new RuntimeException("Pet não encontrado com o ID: " + petId);
        }

        Page<EventoSaude> eventos = repository.findByPetIdOrderByDataEventoDesc(petId, paginacao);

        return eventos.map(evento -> new EventoSaudeResponseDTO(
                evento.getId(),
                evento.getPet().getId(),
                evento.getTipoEvento(),
                evento.getDescricao(),
                evento.getDataEvento(),
                evento.getPet().getHealthScore()
        ));
    }
}