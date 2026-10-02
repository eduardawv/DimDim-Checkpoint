package br.com.fiap.clyvo.controller;

import br.com.fiap.clyvo.dto.VeterinarioAuthResponseDTO;
import br.com.fiap.clyvo.dto.VeterinarioLoginRequestDTO;
import br.com.fiap.clyvo.dto.VeterinarioRequestDTO;
import br.com.fiap.clyvo.dto.VeterinarioResponseDTO;
import br.com.fiap.clyvo.service.VeterinarioService;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/veterinarios")
@CrossOrigin(origins = "*")
public class VeterinarioController {

    @Autowired
    private VeterinarioService service;

    @PostMapping
    public ResponseEntity<VeterinarioResponseDTO> cadastrar(
            @Valid @RequestBody VeterinarioRequestDTO dto) {

        VeterinarioResponseDTO response = service.cadastrar(dto);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<VeterinarioAuthResponseDTO> login(
            @Valid @RequestBody VeterinarioLoginRequestDTO dto) {

        VeterinarioAuthResponseDTO response = service.autenticar(dto);

        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<Page<VeterinarioResponseDTO>> listar(
            @ParameterObject
            @PageableDefault(size = 10, sort = {"nome"})
            Pageable paginacao) {

        Page<VeterinarioResponseDTO> page = service.listar(paginacao);

        return ResponseEntity.ok(page);
    }

    @GetMapping("/{id}")
    public ResponseEntity<VeterinarioResponseDTO> buscarPorId(
            @PathVariable Long id) {

        VeterinarioResponseDTO response = service.buscarPorId(id);

        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<VeterinarioResponseDTO> atualizar(
            @PathVariable Long id,
            @Valid @RequestBody VeterinarioRequestDTO dto) {

        VeterinarioResponseDTO response =
                service.atualizar(id, dto);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @PathVariable Long id) {

        service.excluir(id);

        return ResponseEntity.noContent().build();
    }
}