package br.com.fiap.clyvo.service;

import br.com.fiap.clyvo.dto.EventoSaudeRequestDTO;
import br.com.fiap.clyvo.dto.EventoSaudeResponseDTO;
import br.com.fiap.clyvo.model.EventoSaude;
import br.com.fiap.clyvo.model.Pet;
import br.com.fiap.clyvo.repository.EventoSaudeRepository;
import br.com.fiap.clyvo.repository.PetRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.cache.annotation.CacheEvict;

@Service
public class EventoSaudeService {

    private final EventoSaudeRepository repository;
    private final PetRepository petRepository;
    private final PetService petService;

    public EventoSaudeService(
            EventoSaudeRepository repository,
            PetRepository petRepository,
            PetService petService
    ) {
        this.repository = repository;
        this.petRepository = petRepository;
        this.petService = petService;
    }


    private EventoSaudeResponseDTO toResponse(EventoSaude evento, Pet pet) {
        return new EventoSaudeResponseDTO(
                evento.getId(),
                pet.getId(),
                evento.getTipoEvento(),
                evento.getDescricao(),
                evento.getDataEvento(),
                pet.getHealthScore()
        );
    }


    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public EventoSaudeResponseDTO cadastrarEvento(EventoSaudeRequestDTO dto) {

        Pet pet = petService.buscarPetAutorizado(dto.petId());

        EventoSaude evento = new EventoSaude();
        evento.setPet(pet);
        evento.setTipoEvento(dto.tipoEvento());
        evento.setDescricao(dto.descricao());
        evento.setDataEvento(dto.dataEvento());

        int novoScore = dto.tipoEvento().calcularNovoScore(pet.getHealthScore());

        pet.setHealthScore(novoScore);
        petRepository.save(pet);

        evento = repository.save(evento);

        return toResponse(evento, pet);
    }

    @Transactional(readOnly = true)
    public Page<EventoSaudeResponseDTO> buscarEventosPorPet(Long petId, Pageable paginacao) {

        Pet pet = petService.buscarPetAutorizado(petId);

        Page<EventoSaude> eventos =
                repository.findByPetIdOrderByDataEventoDesc(pet.getId(), paginacao);

        return eventos.map(evento -> toResponse(evento, pet));
    }
}
