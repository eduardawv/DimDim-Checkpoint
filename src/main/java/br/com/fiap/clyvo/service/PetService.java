package br.com.fiap.clyvo.service;

import br.com.fiap.clyvo.dto.PetRequestDTO;
import br.com.fiap.clyvo.dto.PetResponseDTO;
import br.com.fiap.clyvo.exception.AcessoNegadoException;
import br.com.fiap.clyvo.exception.RecursoNaoEncontradoException;
import br.com.fiap.clyvo.model.Pet;
import br.com.fiap.clyvo.model.Tutor;
import br.com.fiap.clyvo.repository.PetRepository;
import br.com.fiap.clyvo.repository.TutorRepository;
import br.com.fiap.clyvo.security.AuthUser;
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
    private final AuthUser authUser; // NOVO - Sprint 4

    public PetService(
            PetRepository petRepository,
            TutorRepository tutorRepository,
            AuthUser authUser
    ) {
        this.petRepository = petRepository;
        this.tutorRepository = tutorRepository;
        this.authUser = authUser;
    }


    private PetResponseDTO toResponse(Pet pet) {
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


    @Transactional(readOnly = true)
    public Pet buscarPetAutorizado(Long id) {
        Pet pet = petRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException(
                        "Pet não encontrado com o ID: " + id));

        if (authUser.isTutor()
                && !pet.getTutor().getId().equals(authUser.getId())) {
            throw new AcessoNegadoException(
                    "Este pet não pertence ao tutor autenticado.");
        }

        return pet;
    }


    @Cacheable(
            value = "listaDePets",
            key = "@authUser.id + '_' + (#nome == null ? '' : #nome) "
                    + "+ '_' + #paginacao.pageNumber + '_' + #paginacao.pageSize"
    )
    @Transactional(readOnly = true)
    public Page<PetResponseDTO> listar(String nome, Pageable paginacao) {

        boolean filtrandoPorNome = nome != null && !nome.trim().isEmpty();
        Page<Pet> pets;

        if (authUser.isTutor()) {
            Long tutorId = authUser.getId();
            pets = filtrandoPorNome
                    ? petRepository.findByTutorIdAndNomeContainingIgnoreCase(tutorId, nome, paginacao)
                    : petRepository.findByTutorId(tutorId, paginacao);
        } else {

            pets = filtrandoPorNome
                    ? petRepository.findByNomeContainingIgnoreCase(nome, paginacao)
                    : petRepository.findAll(paginacao);
        }

        return pets.map(this::toResponse);
    }


    @Transactional(readOnly = true)
    public PetResponseDTO buscarPorId(Long id) {
        return toResponse(buscarPetAutorizado(id));
    }


    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public PetResponseDTO cadastrar(PetRequestDTO dto) {

        Long tutorId;

        if (authUser.isTutor()) {
            tutorId = authUser.getId();
        } else {
            tutorId = dto.tutorId();
            if (tutorId == null) {
                throw new IllegalArgumentException(
                        "O veterinário precisa informar o tutorId do pet.");
            }
        }

        Tutor tutor = tutorRepository.findById(tutorId)
                .orElseThrow(() -> new RecursoNaoEncontradoException(
                        "Tutor não encontrado com o ID: " + tutorId));

        Pet pet = new Pet();
        pet.setNome(dto.nome());
        pet.setEspecie(dto.especie());
        pet.setRaca(dto.raca());
        pet.setPeso(dto.peso());
        pet.setIdade(dto.idade());
        pet.setTutor(tutor);
        pet.setHealthScore(100);

        pet = petRepository.save(pet);

        return toResponse(pet);
    }

    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public PetResponseDTO atualizar(Long id, PetRequestDTO dto) {

        Pet pet = buscarPetAutorizado(id);

        pet.setNome(dto.nome());
        pet.setEspecie(dto.especie());
        pet.setRaca(dto.raca());
        pet.setPeso(dto.peso());
        pet.setIdade(dto.idade());


        pet = petRepository.save(pet);

        return toResponse(pet);
    }


    @CacheEvict(value = "listaDePets", allEntries = true)
    @Transactional
    public void excluir(Long id) {
        Pet pet = buscarPetAutorizado(id);
        petRepository.delete(pet);
    }
}
