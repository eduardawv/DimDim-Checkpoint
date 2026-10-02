package br.com.fiap.clyvo.controller;

import br.com.fiap.clyvo.dto.PetRequestDTO;
import br.com.fiap.clyvo.dto.PetResponseDTO;
import br.com.fiap.clyvo.dto.ia.PetRegistrationAiResponseDTO;
import br.com.fiap.clyvo.service.ClyvoAiService;
import br.com.fiap.clyvo.service.PetService;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

@RestController
@RequestMapping("/api/pets")
public class PetController {

    private final PetService petService;
    private final ClyvoAiService clyvoAiService;

    public PetController(
            PetService petService,
            ClyvoAiService clyvoAiService
    ) {
        this.petService = petService;
        this.clyvoAiService = clyvoAiService;
    }

    @PostMapping
    public ResponseEntity<PetResponseDTO> cadastrar(
            @Valid @RequestBody PetRequestDTO dto
    ) {
        PetResponseDTO response = petService.cadastrar(dto);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @GetMapping
    public ResponseEntity<Page<PetResponseDTO>> listar(
            @RequestParam(required = false) String nome,
            @ParameterObject
            @PageableDefault(size = 10, sort = {"nome"})
            Pageable paginacao
    ) {
        Page<PetResponseDTO> page =
                petService.listar(nome, paginacao);

        return ResponseEntity.ok(page);
    }

    @GetMapping("/{id}")
    public ResponseEntity<PetResponseDTO> buscarPorId(
            @PathVariable Long id
    ) {
        PetResponseDTO response =
                petService.buscarPorId(id);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<PetResponseDTO> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody PetRequestDTO dto
    ) {
        PetResponseDTO response =
                petService.atualizar(id, dto);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @PathVariable Long id
    ) {
        petService.excluir(id);

        return ResponseEntity
                .noContent()
                .build();
    }

    @PostMapping(
            value = "/analisar-cadastro",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<PetRegistrationAiResponseDTO> analisarCadastro(
            @RequestParam("imagem") MultipartFile imagem
    ) throws IOException {

        PetRegistrationAiResponseDTO resposta =
                clyvoAiService.analisarFotoCadastro(imagem);

        return ResponseEntity.ok(resposta);
    }
}