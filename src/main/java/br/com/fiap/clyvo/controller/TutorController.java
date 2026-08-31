package br.com.fiap.clyvo.controller;

import br.com.fiap.clyvo.dto.TutorRequestDTO;
import br.com.fiap.clyvo.dto.TutorResponseDTO;
import br.com.fiap.clyvo.dto.TutorLoginRequestDTO;
import br.com.fiap.clyvo.dto.TutorAuthResponseDTO;
import br.com.fiap.clyvo.service.TutorService;
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
@RequestMapping("/api/tutores")
@CrossOrigin(origins = "*") // Permite que o aplicativo mobile se conecte aqui
public class TutorController {

    @Autowired
    private TutorService service;

    @PostMapping
    public ResponseEntity<TutorResponseDTO> cadastrar(@Valid @RequestBody TutorRequestDTO dto) {
        TutorResponseDTO response = service.cadastrar(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<TutorAuthResponseDTO> login(@Valid @RequestBody TutorLoginRequestDTO dto) {
        TutorAuthResponseDTO response = service.autenticar(dto);
        return ResponseEntity.ok(response);
    }

    @GetMapping
    public ResponseEntity<Page<TutorResponseDTO>> listar(
            @ParameterObject @PageableDefault(size = 10, sort = {"nome"}) Pageable paginacao) {
        Page<TutorResponseDTO> page = service.listar(paginacao);
        return ResponseEntity.ok(page);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TutorResponseDTO> buscarPorId(@PathVariable Long id) {
        TutorResponseDTO response = service.buscarPorId(id);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TutorResponseDTO> atualizar(@PathVariable Long id, @Valid @RequestBody TutorRequestDTO dto) {
        TutorResponseDTO response = service.atualizar(id, dto);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(@PathVariable Long id) {
        service.excluir(id);
        return ResponseEntity.noContent().build();
    }
}
