package br.com.fiap.clyvo.service;

import br.com.fiap.clyvo.dto.PetRequestDTO;
import br.com.fiap.clyvo.dto.PetResponseDTO;
import br.com.fiap.clyvo.model.Pet;
import br.com.fiap.clyvo.model.Tutor;
import br.com.fiap.clyvo.repository.PetRepository;
import br.com.fiap.clyvo.repository.TutorRepository;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PetService {

    private final PetRepository petRepository;
    private final TutorRepository tutorRepository;

    public PetService(PetRepository petRepository, TutorRepository tutorRepository) {
        this.petRepository = petRepository;
        this.tutorRepository = tutorRepository;
    }

    @Cacheable(value = "listaDePets")
    @Transactional(readOnly = true)
    public Page<PetResponseDTO> listar(String nome, Pageable paginacao) {
        Page<Pet> pets;

        if (nome != null && !nome.trim().isEmpty()) {
            pets = petRepository.findByNomeContainingIgnoreCase(nome, paginacao);
        } else {
            pets = petRepository.findAll(paginacao);
        }

        return pets.map(pet -> new PetResponseDTO(
                pet.getId(),
                pet.getNome(),
                pet.getEspecie(),
                pet.getRaca(),
                pet.getIdade(),
                pet.getPeso(),
                pet.getHealthScore(),
                pet.getTutor().getId()
        ));
    }

    @Transactional(readOnly = true)
    public PetResponseDTO buscarPorId(Long id) {
        Pet pet = petRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pet não encontrado com o ID: " + id));

        return new PetResponseDTO(
                pet.getId(),
                pet.getNome(),
                pet.getEspecie(),
                pet.getRaca(),
                pet.getIdade(),
                pet.getPeso(),
                pet.getHealthScore(),
                pet.getTutor().getId()
        );
    }

    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public PetResponseDTO cadastrar(PetRequestDTO dto) {
        Tutor tutor = tutorRepository.findById(dto.tutorId())
                .orElseThrow(() -> new RuntimeException("Tutor não encontrado com o ID: " + dto.tutorId()));

        Pet pet = new Pet();
        pet.setNome(dto.nome());
        pet.setEspecie(dto.especie());
        pet.setRaca(dto.raca());
        pet.setPeso(dto.peso());
        pet.setIdade(dto.idade());
        pet.setTutor(tutor);
        pet.setHealthScore(100);

        pet = petRepository.save(pet);

        return new PetResponseDTO(
                pet.getId(),
                pet.getNome(),
                pet.getEspecie(),
                pet.getRaca(),
                pet.getIdade(),
                pet.getPeso(),
                pet.getHealthScore(),
                pet.getTutor().getId()
        );
    }

    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public PetResponseDTO atualizar(Long id, PetRequestDTO dto) {
        Pet pet = petRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Pet não encontrado com o ID: " + id));

        pet.setNome(dto.nome());
        pet.setEspecie(dto.especie());
        pet.setRaca(dto.raca());
        pet.setPeso(dto.peso());
        pet.setIdade(dto.idade());

        pet = petRepository.save(pet);

        return new PetResponseDTO(
                pet.getId(),
                pet.getNome(),
                pet.getEspecie(),
                pet.getRaca(),
                pet.getIdade(),
                pet.getPeso(),
                pet.getHealthScore(),
                pet.getTutor().getId()
        );
    }

    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public void excluir(Long id) {
        if (!petRepository.existsById(id)) {
            throw new RuntimeException("Pet não encontrado com o ID: " + id);
        }
        petRepository.deleteById(id);
    }
}