package br.com.fiap.clyvo.controller;

import br.com.fiap.clyvo.dto.EventoSaudeRequestDTO;
import br.com.fiap.clyvo.dto.EventoSaudeResponseDTO;
import br.com.fiap.clyvo.service.EventoSaudeService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/eventos")
@CrossOrigin(origins = "*") // Libera o acesso para o aplicativo mobile
public class EventoSaudeController {

    @Autowired
    private EventoSaudeService service;

    @PostMapping
    public ResponseEntity<EventoSaudeResponseDTO> cadastrarEvento(@Valid @RequestBody EventoSaudeRequestDTO dto) {
        EventoSaudeResponseDTO eventoSalvo = service.cadastrarEvento(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(eventoSalvo);
    }


    @GetMapping("/pet/{petId}")
    public ResponseEntity<Page<EventoSaudeResponseDTO>> listarEventosPorPet(
            @PathVariable Long petId,
            @PageableDefault(size = 10, sort = "dataEvento") Pageable paginacao) {

        Page<EventoSaudeResponseDTO> eventos = service.buscarEventosPorPet(petId, paginacao);
        return ResponseEntity.ok(eventos);
    }
}